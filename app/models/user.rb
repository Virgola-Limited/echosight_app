# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
#  confirmation_sent_at         :datetime
#  confirmation_token           :string
#  confirmed_at                 :datetime
#  consumed_timestep            :integer
#  current_sign_in_at           :datetime
#  current_sign_in_ip           :string
#  email                        :string           default(""), not null
#  enabled_without_subscription :boolean          default(FALSE)
#  encrypted_password           :string           default(""), not null
#  failed_attempts              :integer          default(0), not null
#  invitation_accepted_at       :datetime
#  invitation_created_at        :datetime
#  invitation_limit             :integer
#  invitation_sent_at           :datetime
#  invitation_token             :string
#  invitations_count            :integer          default(0)
#  invited_by_type              :string
#  last_name                    :string
#  last_sign_in_at              :datetime
#  last_sign_in_ip              :string
#  locked_at                    :datetime
#  name                         :string
#  otp_required_for_login       :boolean
#  otp_secret                   :string
#  remember_created_at          :datetime
#  reset_password_sent_at       :datetime
#  reset_password_token         :string
#  sign_in_count                :integer          default(0), not null
#  unconfirmed_email            :string
#  unlock_token                 :string
#  vip_since                    :date
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  invited_by_id                :bigint
#  stripe_customer_id           :string
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by            (invited_by_type,invited_by_id)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_stripe_customer_id    (stripe_customer_id)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#

class User < ApplicationRecord
  has_subscriptions

  devise :invitable, :invitable, :registerable, :two_factor_authenticatable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter2]

  before_create :generate_otp_secret

  has_one :identity, dependent: :destroy
  has_many :feature_requests
  has_many :bug_reports
  has_many :sent_emails, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :tweets, through: :identity
  has_many :tweet_metrics, through: :tweets
  has_many :twitter_user_metrics, through: :identity
  has_many :user_settings, dependent: :destroy

  attr_accessor :otp_code

  %i[handle banner_url image_url enough_data_for_public_page? page_low_on_recent_data?].each do |method|
    delegate method, to: :identity, allow_nil: true
  end

  after_create :subscribe_to_all_lists, :enqueue_create_stripe_customer

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[confirmation_sent_at confirmation_token confirmed_at created_at current_sign_in_at
       current_sign_in_ip email encrypted_password failed_attempts id id_value last_name last_sign_in_at last_sign_in_ip locked_at name remember_created_at reset_password_sent_at reset_password_token sign_in_count unconfirmed_email unlock_token updated_at]
  end

  def active_subscription?
    if subscriptions.active.count > 1
      ExceptionNotifier.notify_exception(StandardError.new('User has more than one active subscription'),
                                         data: { user_id: id })
    end
    subscriptions.active.count.positive?
  end

  def accepted_invitation?
    invitation_accepted_at.present?
  end

  def setting(key)
    get_setting_value(key)
  end

  def syncable?
    identity&.syncable?
  end

  def create_or_update_identity_from_omniauth(auth)
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid)

    ActiveRecord::Base.transaction do
      assign_from_auth(auth)

      save!

      identity ||= self.build_identity
      Rails.logger.debug('paul identity' + identity.inspect)
      identity.assign_attributes_from_auth(auth)

      oauth_credential = identity.oauth_credential || identity.build_oauth_credential
      oauth_credential.assign_attributes(
        token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        expires_at: Time.at(auth.credentials.expires_at)
      )

      identity.save! if identity.new_record? || identity.changed?
      oauth_credential.save! if oauth_credential.new_record? || oauth_credential.changed?
    end

    self
  end

  def assign_from_auth(auth)
    self.name = auth.info.name if name.blank?
    self.email = auth.info.email if email.blank?
  end

  def eligible_for_trial?
    accepted_invitation? && ENV.fetch('TRIAL_PERIOD_DAYS', 0).to_i.positive?
  end

  def guest?
    !persisted?
  end

  def connected_to_twitter?
    identity&.provider == 'twitter2'
  end

  def method_missing(method_name, *arguments, &block)
    if setting_method?(method_name)
      key = extract_key_from_method(method_name)
      get_setting_value(key)
    else
      super
    end
  end

  def otp_qr_code
    issuer = ERB::Util.url_encode("EchoSight")
    label = "#{issuer}:#{email}"

    logo_url = Rails.application.config.asset_host + '/static_images/logo.png'
    uri = "otpauth://totp/#{ERB::Util.url_encode(label)}?secret=#{otp_secret}&issuer=#{ERB::Util.url_encode(issuer)}&logo=#{ERB::Util.url_encode(logo_url)}"
    Rails.logger.debug "OTP URI: #{uri}"

    qrcode = RQRCode::QRCode.new(uri)

    # Create the base QR code as a PNG image
    png = qrcode.as_png(size: 300)

    # Save the QR code image to a temporary file
    qr_tempfile = Tempfile.new(['qrcode', '.png'])
    qr_tempfile.binmode
    qr_tempfile.write(png.to_s)
    qr_tempfile.rewind

    # Load the QR code and logo images using MiniMagick
    qr_image = MiniMagick::Image.open(qr_tempfile.path)
    logo_path = Rails.root.join('app', 'javascript', 'images', 'logo.png')
    raise "Logo file not found at #{logo_path}" unless File.exist?(logo_path)
    logo_image = MiniMagick::Image.open(logo_path)

    # Resize the logo if necessary
    logo_image.resize '50x50'
    Rails.logger.debug "Logo resized"

    # Composite the logo onto the QR code
    result = qr_image.composite(logo_image) do |c|
      c.gravity 'Center'
    end

    Rails.logger.debug "**Logo composited onto QR code"

    # Save the composited image for verification
    result.write(Rails.root.join('tmp', 'composited_qr_code.png'))

    # Return the QR code as a base64-encoded image
    result.format 'png'
    encoded_image = Base64.encode64(result.to_blob).gsub("\n", '')
    Rails.logger.debug "**Base64 encoded image generated"

    encoded_image
  end

  private

  def convert_to_boolean(value)
    return true if value == 'true'
    return false if value == 'false'
    value
  end

  def generate_otp_secret
    self.otp_secret = ROTP::Base32.random_base32
  end

  def get_setting_value(key)
    value = user_settings.find_by(key: key.to_s)&.value || UserSetting.default_value(key.to_s)
    convert_to_boolean(value)
  end

  def setting_method?(method_name)
    method_name.to_s.end_with?('?') && UserSetting::VALID_KEYS.include?(extract_key_from_method(method_name).to_s)
  end

  def extract_key_from_method(method_name)
    method_name.to_s.chomp('?')
  end

  def enqueue_create_stripe_customer
    CreateStripeCustomerWorkerJob.perform_async(id)
  end

  def subscribe_to_all_lists
    MAILKICK_SUBSCRIPTION_LISTS.each do |list|
      Mailkick::Subscription.create!(subscriber: self, list:)
    end
  end
end

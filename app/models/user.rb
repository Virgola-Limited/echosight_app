# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by            (invited_by_type,invited_by_id)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  devise :invitable, :database_authenticatable, :invitable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter2]

  has_one :identity, dependent: :destroy
  has_many :tweets, through: :identity
  has_many :tweet_metrics, through: :tweets
  has_many :twitter_user_metrics, through: :identity

  delegate :handle, to: :identity, allow_nil: true
  delegate :banner_url, to: :identity, allow_nil: true
  delegate :image_url, to: :identity, allow_nil: true

  after_commit :enqueue_twitter_data_pull, on: %i[create update]

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  has_one :latest_hourly_tweet_count, -> { order(start_time: :desc) }, through: :identity, source: :hourly_tweet_counts

  def self.ransackable_attributes(auth_object = nil)
    ["confirmation_sent_at", "confirmation_token", "confirmed_at", "created_at", "current_sign_in_at", "current_sign_in_ip", "email", "encrypted_password", "failed_attempts", "id", "id_value", "last_name", "last_sign_in_at", "last_sign_in_ip", "locked_at", "name", "remember_created_at", "reset_password_sent_at", "reset_password_token", "sign_in_count", "unconfirmed_email", "unlock_token", "updated_at"]
  end

  def self.from_omniauth(auth)
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid)

    if identity
      user = identity.user
    else
      user = User.find_or_initialize_by(email: auth.info.email)
      user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?
    end

    # Update user's attributes
    user.name = auth.info.name if user.name.blank?
    user.email = auth.info.email if user.email.blank?
    user.email = "fake_email_#{rand(252...4350)}@echosight.io" if user.email.blank?

    # Extract and update description with original URLs
    description = auth.info.description

    urls = auth.extra.raw_info.data.entities.description.urls rescue []

    urls.each do |url_object|
      replaced = description.gsub!(url_object.url, url_object.expanded_url)
    end

    # Update or build identity
    identity ||= user.build_identity
    identity.assign_attributes(
      provider: auth.provider,
      uid: auth.uid,
      description: description,
      handle: auth.extra.raw_info.data.username,
    )

    # Update or build oauth_credential
    oauth_credential = identity.oauth_credential || identity.build_oauth_credential
    oauth_credential.assign_attributes(
      provider: auth.provider,
      token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      expires_at: Time.at(auth.credentials.expires_at)
    )

    # Save user, identity, and oauth_credential
    ActiveRecord::Base.transaction do
      user.save! if user.new_record? || user.changed?
      identity.save! if identity.new_record? || identity.changed?
      oauth_credential.save! #if oauth_credential.new_record? || oauth_credential.changed?
    end

    user
  end

  def self.create_or_update_identity_from_omniauth(auth)
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid)
    user = identity.try(:user)

    if user.nil?
      # Find or initialize the user by email
      user = User.find_or_initialize_by(email: auth.info.email)
      user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?
      # Auto-confirm only if the user is new and created via OmniAuth
      user.confirm if user.new_record?
    end

    # Update user's attributes
    user.assign_from_auth(auth)

    # Update or create identity and oauth_credential
    ActiveRecord::Base.transaction do
      user.save! if user.new_record? || user.changed?

      identity ||= user.build_identity
      identity.assign_attributes_from_auth(auth) # Ensure this method exists in the Identity model to handle auth data

      oauth_credential = identity.oauth_credential || identity.build_oauth_credential
      oauth_credential.assign_attributes(
        token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        expires_at: Time.at(auth.credentials.expires_at)
      )

      identity.save! if identity.new_record? || identity.changed?
      oauth_credential.save! if oauth_credential.new_record? || oauth_credential.changed?
    end

    user
  end


  def assign_from_auth(auth)
    self.name = auth.info.name if name.blank?
    self.email = auth.info.email if email.blank?
    self.email = "fake_email_#{rand(252...4350)}@echosight.io" if email.blank?
  end

  def update_identity_from_auth(auth)
    identity = self.identity || build_identity
    identity.assign_attributes(
      provider: auth.provider,
      uid: auth.uid,
      image_url: auth.info.image,
      description: auth.info.description,
      handle: auth.extra.raw_info.data.username
    )
    identity.save!
  end


  def guest?
    !persisted?
  end

  def connected_to_twitter?
    identity&.provider == 'twitter2'
  end

  private

  def enqueue_twitter_data_pull
    return unless confirmed_at_changed? && confirmed_at_was.nil?

    # Twitter::UpdateTwitterDataJob.perform_async(user_id: id)
  end
end

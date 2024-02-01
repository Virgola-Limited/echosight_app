# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter2]

  has_one :identity, dependent: :destroy

  delegate :handle, to: :identity, allow_nil: true
  delegate :banner_url, to: :identity, allow_nil: true
  delegate :image_url, to: :identity, allow_nil: true

  after_commit :enqueue_hourly_tweet_counts_update, on: %i[create update]

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  has_one :latest_hourly_tweet_count, -> { order(start_time: :desc) }, through: :identity, source: :hourly_tweet_counts

  def self.from_omniauth(auth)
    # make this work when already logged in and adding twitter (check current user)
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
    # OAUTH2 doesnt support getting email address need to move back to OAUTH1 or ask user for email
    ##########################  TODO REMOVE THIS BEFORE LAUNCH
    user.email = "fake_email_#{rand(252...4350)}@echosight.io" if user.email.blank?
    ##########################  TODO REMOVE THIS BEFORE LAUNCH

    # Update or build identity
    identity ||= user.build_identity
    identity.assign_attributes(
      provider: auth.provider,
      uid: auth.uid,
      image_url: auth.info.image,
      description: auth.info.description,
      handle: auth.extra.raw_info.data.username,
      # this disappeared from auth when we moved to omniauth2 ???
      # banner_url: auth.extra.raw_info.profile_banner_url,
      bearer_token: auth.credentials.token
    )

    # Save user and identity
    ActiveRecord::Base.transaction do
      user.save! if user.new_record? || user.changed?
      identity.save! if identity.new_record? || identity.changed?
    end

    user
  end

  def guest?
    !persisted?
  end

  private

  def enqueue_hourly_tweet_counts_update
    return unless confirmed_at_changed? && confirmed_at_was.nil?

    Twitter::UpdateTwitterDataWorker.perform_async(user_id: id)
  end
end

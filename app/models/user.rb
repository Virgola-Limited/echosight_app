# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter2]

  has_one :identity, dependent: :destroy

  delegate :twitter_handle, to: :identity, allow_nil: true
  delegate :banner_url, to: :identity, allow_nil: true
  delegate :image_url, to: :identity, allow_nil: true

  after_commit :enqueue_tweet_hourly_counts_update, on: %i[create update]

  def self.from_omniauth(auth)
    Rails.logger.debug("paul auth#{auth.inspect}")
    # We arent getting email from Twitter even though its set up in:

    # https://developer.twitter.com/en/portal/projects/1722744715408449536/apps/28231960/auth-settings

    # <OmniAuth::AuthHash credentials=#<OmniAuth::AuthHash expires=true expires_at=1704066405 token="dlJRS2hNdlRValZYay1SWEtQSzIySmFwYjRzaVI2UU5rY1IySnJORHRfRGhGOjE3MDQwNTkyMDUxNjc6MTowOmF0OjE"> extra=#<OmniAuth::AuthHash raw_info=#<SnakyHash::StringKeyed data=#<SnakyHash::StringKeyed created_at="2023-08-16T21:52:25.000Z" description="\"Any sufficiently advanced technology is equivalent to magic.” - Arthur C. Clarke" id="1691930809756991488" name="Topher" profile_image_url="https://pbs.twimg.com/profile_images/1729697224278552576/pa9ZhTkQ_normal.jpg" protected=false public_metrics=#<SnakyHash::StringKeyed followers_count=1 following_count=12 like_count=0 listed_count=0 tweet_count=2> username="Topher179412184" verified=false>>> info=#<OmniAuth::AuthHash::InfoHash description="\"Any sufficiently advanced technology is equivalent to magic.” - Arthur C. Clarke" email=nil image="https://pbs.twimg.com/profile_images/1729697224278552576/pa9ZhTkQ_normal.jpg" name="Topher" nickname="Topher179412184" urls=#<OmniAuth::AuthHash Twitter="https://twitter.com/Topher179412184" Website=nil>> provider="twitter2" uid="1691930809756991488">

    # might be an intermittent Twitter bug so hack in a fake email for now but fix soon if not intermittent.

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
      twitter_handle: auth.extra.raw_info.data.username,
      # this disappeared from auth when we moved to omniauth2 ???
      # banner_url: auth.extra.raw_info.profile_banner_url,
      bearer_token: auth.credentials.token,
      # these might not be needed any longer if we arent using Oauth1
      token: auth.credentials.token,
      secret: auth.credentials.secret
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

  def enqueue_tweet_hourly_counts_update
    return unless confirmed_at_changed? && confirmed_at_was.nil?

    Twitter::TweetHourlyCountsUpdater.perform_async(id, nil)
  end
end

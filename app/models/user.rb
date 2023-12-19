class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter]

  has_one :identity, dependent: :destroy

  delegate :twitter_handle, to: :identity, allow_nil: true
  delegate :banner_url, to: :identity, allow_nil: true
  delegate :image_url, to: :identity, allow_nil: true

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
    # Update or build identity
    identity ||= user.build_identity
    identity.assign_attributes(
      provider: auth.provider,
      uid: auth.uid,
      image_url: auth.info.image,
      description: auth.info.description,
      twitter_handle: auth.extra.raw_info.screen_name,
      banner_url: auth.extra.raw_info.profile_banner_url
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

end

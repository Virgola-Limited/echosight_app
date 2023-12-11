class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter]

  has_one :identity, dependent: :destroy

  def self.from_omniauth(auth)
    user = User.find_or_initialize_by(email: auth.info.email) do |u|
      u.password = Devise.friendly_token[0, 20] if u.encrypted_password.blank?
      u.name = auth.info.name if u.name.blank?
    end

    # Check if the user already has an identity and update it, or build a new one
    identity = user.identity || user.build_identity
    identity.provider = auth.provider
    identity.uid = auth.uid
    identity.image_url = auth.info.image


    # Save user and identity if needed
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

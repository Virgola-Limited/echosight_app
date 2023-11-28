class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable,
         omniauth_providers: [:twitter]

  has_one :identity

  def self.from_omniauth(auth)
    user = User.find_or_initialize_by(email: auth.info.email) do |u|
      u.password = Devise.friendly_token[0, 20] if u.encrypted_password.blank?
      u.name = auth.info.name if u.name.blank?
    end

    identity = user.build_identity(provider: auth.provider, uid: auth.uid)
    user.save if user.new_record? || user.changed? || identity.changed?
    user
  end
end

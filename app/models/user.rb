class User < ApplicationRecord
  # Include default devise modules. Others available are:

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable, omniauth_providers: [:twitter]

  def self.from_omniauth(auth)
    Rails.logger.debug('paul' + auth.inspect)

    user = nil

    # Check if the user's email exists in the database
    if auth.info.email && (existing_user = User.find_by_email(auth.info.email))
      existing_user.provider = auth.provider
      existing_user.uid = auth.uid
      user = existing_user
    else
      user = where(provider: auth.provider, uid: auth.uid).first_or_initialize
      user.email = auth.info.email if user.email.blank?
      user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?
      user.name = auth.info.name if user.name.blank?
    end

    # do we want to automatically confirm the user email if:after =>
    # A. come from twitter and doesnt existing in our database
    # B. Can they sign up without using Twitter to start with - perhaps we disable normal sign up for now?



    # Save the user record if it's new or has been changed
    user.save if user.new_record? || user.changed?
    user
  end
end

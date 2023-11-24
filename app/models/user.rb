class User < ApplicationRecord
  # Include default devise modules. Others available are:

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable, :omniauthable, omniauth_providers: [:twitter]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      # Assume the user model has a name
      user.name = auth.info.name
      # Twitter does not provide email by default so you may need to prompt users for their email on the first login.
    end

    # do we want to automatically confirm the user email if:after =>
    # A. come from twitter and doesnt existing in our database
    # B. Can they sign up without using Twitter to start with - perhaps we disable normal sign up for now?

    # Save the user record if it's new or has been changed
    user.save if user.new_record? || user.changed?
    user
  end
end

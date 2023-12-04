class Users::RegistrationsController < Devise::RegistrationsController
  layout 'authenticated', only: [:edit, :update]

  # Redirect to a custom path after a user signs up but isn't confirmed
  def after_inactive_sign_up_path_for(resource)
    # remove the flash and show a friendly custom message
    flash.delete(:notice)
    single_message_index_path(message_type: :after_sign_up)
  end
end

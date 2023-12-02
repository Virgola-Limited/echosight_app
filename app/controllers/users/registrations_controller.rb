class Users::RegistrationsController < Devise::RegistrationsController
  layout 'authenticated', only: [:edit, :update]

  # Redirect to a custom path after a user signs up but isn't confirmed
  def after_inactive_sign_up_path_for
    # remove the flash and show a friendly custom message
    flash.delete(:notice)
    single_message_index_path(message_type: :after_sign_up)
  end

  # Define the path after the user confirms their account
  def after_confirmation_path_for(
    log them in with the flash message for confirming
  end
end

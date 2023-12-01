# test/mailers/previews/devise_mailer_preview.rb

class DeviseMailerPreview < ActionMailer::Preview
  # Preview the confirmation instructions email
  def confirmation_instructions
    User.first.send_confirmation_instructions
  end

  # Preview the email changed notification email
  def email_changed
    user = User.first
    user.unconfirmed_email = "new_email@example.com" # Mock new email
    Devise::Mailer.email_changed(user)
  end

  # Preview the password change confirmation email
  def password_change
    Devise::Mailer.password_change(User.first)
  end

  # Preview the reset password instructions email
  def reset_password_instructions
    User.first.send_reset_password_instructions
  end

  # Preview the unlock instructions email
  def unlock_instructions
    User.first.send_unlock_instructions
  end
end

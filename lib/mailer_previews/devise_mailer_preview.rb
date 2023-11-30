# test/mailers/previews/devise_mailer_preview.rb

class DeviseMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/devise_mailer/confirmation_instructions
  def confirmation_instructions
   User.first.send_confirmation_instructions
  end
end
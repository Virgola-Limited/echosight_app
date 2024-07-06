# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/users_without_subscription_email
  def users_without_subscription_email
    UserMailer.users_without_subscription_email(User.first)
  end
end

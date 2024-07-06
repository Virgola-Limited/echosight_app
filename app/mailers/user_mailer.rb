class UserMailer < ApplicationMailer

  def users_without_subscription_email(user)
    @mail_type = 'users_without_subscription_email'
    @is_transactional_email = true
    @user = user
    mail(to: @user.email, subject: 'We Want to Hear From You!')
  end
end

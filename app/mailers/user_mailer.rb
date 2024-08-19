class UserMailer < ApplicationMailer

  def users_without_subscription_email(user)
    @mail_type = 'users_without_subscription_email'
    @is_transactional_email = true
    @user = user
    mail(to: @user.email, subject: 'We Want to Hear From You!')
  end

  def send_individual_email(user, subject, body)
    @mail_type = 'bulk_email'
    @is_transactional_email = true
    @user = user
    mail(to: @user.email, subject: subject, body: body)
  end

end

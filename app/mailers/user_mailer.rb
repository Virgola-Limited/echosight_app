class UserMailer < ApplicationMailer

  def feedback_request(user)
    @is_transactional_email = true
    @user = user
    mail(to: @user.email, subject: 'We Want to Hear From You!')
  end
end

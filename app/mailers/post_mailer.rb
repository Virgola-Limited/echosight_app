class PostMailer < ApplicationMailer

  def post_failed_email(message, reasons)
    @is_transactional_email = true
    @user = User.first
    @message = message
    @reasons = reasons
    mail(to: @user.email, subject: 'Post Sending Failed Notification')
  end
end
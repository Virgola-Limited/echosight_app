class PostMailer < ApplicationMailer
  def post_failed_email(message, reasons)
    @message = message
    @reasons = reasons
    mail(to: 'ctoynbee@gmail.com', subject: 'Post Sending Failed Notification')
  end
end
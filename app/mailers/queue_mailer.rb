class QueueMailer < ApplicationMailer

  def queue_size_alert(queue_name, queue_size)
    @is_transactional_email = true
    @user = User.first
    @queue_name = queue_name
    @queue_size = queue_size
    mail(to: @user.email, subject: 'Sidekiq Queue Size Alert')
  end
end

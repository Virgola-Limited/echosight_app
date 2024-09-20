# app/jobs/identity_notification_job.rb
class IdentityNotificationJob
  include Sidekiq::Job

  def perform
    IdentityNotificationService.new.run
  end
end

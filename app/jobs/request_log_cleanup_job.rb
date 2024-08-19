class RequestLogCleanupJob
  include Sidekiq::Job

  def perform
    RequestLog.cleanup_old_logs
  end
end
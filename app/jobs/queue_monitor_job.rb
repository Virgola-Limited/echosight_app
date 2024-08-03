class QueueMonitorJob
  include Sidekiq::Job

  def perform
    queue_threshold = 20
    scheduled_threshold = 300

    Sidekiq::Queue.all.each do |queue|
      if queue.size >= queue_threshold
        message = "The #{queue.name} queue has reached a size of #{queue.size}"
        Notifications::SlackNotifier.call(message: message, channel: :general)
      end
    end

    scheduled_size = Sidekiq::ScheduledSet.new.size
    if scheduled_size < scheduled_threshold
      message = "The scheduled queue has dropped below #{scheduled_threshold} with a size of #{scheduled_size}"
      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end

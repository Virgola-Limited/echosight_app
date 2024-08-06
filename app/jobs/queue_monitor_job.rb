class QueueMonitorJob
  include Sidekiq::Job

  def perform
    queue_threshold = 20
    enqueued_threshold = 100
    scheduled_threshold = 500

    Sidekiq::Queue.all.each do |queue|
      if queue.size >= queue_threshold
        message = "The #{queue.name} queue has reached a size of #{queue.size}"
        Notifications::SlackNotifier.call(message: message, channel: :errors)
      end

      if queue.size >= enqueued_threshold
        message = "The #{queue.name} queue has #{queue.size} enqueued jobs"
        Notifications::SlackNotifier.call(message: message, channel: :errors)
      end
    end

    scheduled_size = Sidekiq::ScheduledSet.new.size
    if scheduled_size < scheduled_threshold
      message = "The scheduled queue has dropped below #{scheduled_threshold} with a size of #{scheduled_size}"
      Notifications::SlackNotifier.call(message: message, channel: :errors)
    end
  end
end

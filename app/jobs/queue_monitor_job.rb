class QueueMonitorJob
  include Sidekiq::Job

  def perform
    queue_threshold = 20

    Sidekiq::Queue.all.each do |queue|
      if queue.size >= queue_threshold
        message = "The #{queue.name} queue has reached a size of #{queue.size}"
        Notifications::SlackNotifier.call(message: message, channel: :errors)
      end
    end
  end
end

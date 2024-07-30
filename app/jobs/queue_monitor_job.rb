class QueueMonitorJob
  include Sidekiq::Job

  def perform
    queue_threshold = 20  # Set your desired threshold here

    Sidekiq::Queue.all.each do |queue|
      if queue.size >= queue_threshold
        QueueMailer.queue_size_alert(queue.name, queue.size).deliver_now
      end
    end
  end
end
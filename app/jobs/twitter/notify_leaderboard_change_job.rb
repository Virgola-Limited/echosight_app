# app/jobs/twitter/notify_leaderboard_change_job.rb
module Twitter
  class NotifyLeaderboardChangeJob
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, retry: 5

    def perform
      Twitter::LeaderboardNotificationService.new.run
    end
  end
end

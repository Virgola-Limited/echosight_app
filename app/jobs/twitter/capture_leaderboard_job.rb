# app/jobs/capture_leaderboard_job.rb
module Twitter
  class CaptureLeaderboardJob
    include Sidekiq::Job
    sidekiq_options queue: :low_priority

    def perform
      Twitter::LeaderboardSnapshotService.capture_snapshots
    end
  end
end
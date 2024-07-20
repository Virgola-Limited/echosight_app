module Twitter
  class NotifyLeaderboardChangeJob
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, retry: 5

    def perform
      change = Twitter::Leaderboard::LeaderChangeQuery.new.call
      return unless change

      new_leader_handle = change[:new_leader][:twitter_handle]
      message = "Congratulations @#{new_leader_handle} on topping the leaderboard on Echosight!"
      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end

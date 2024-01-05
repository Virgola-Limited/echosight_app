class UpdateTweetHourlyCountsWorker
  include Sidekiq::Worker

  def perform
    confirmed_users.each do |user|
      if needs_update?(user)
        TweetHourlyCountsUpdater.new(user, nil).call
      end
    end
  end

  private

  def confirmed_users
    TwitterIdentity.where(is_confirmed: true).map(&:user)
  end

  def needs_update?(user)
    latest_count_time = user.latest_tweet_hourly_count&.start_time || 1.day.ago.utc
    latest_count_time < 24.hours.ago.utc
  end
end

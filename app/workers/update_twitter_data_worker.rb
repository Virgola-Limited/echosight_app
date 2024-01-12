class UpdateTwitterDataWorker
  include Sidekiq::Worker

  def perform
    confirmed_users.each do |user|
      # if needs_update?(user)
        # Twitter::HourlyTweetCountsUpdater.new(user, nil).call
      # end
      # Later on we should check if the data needs updating to conserve API usage
      Twitter::FollowersUpdater.new(user).call
    end
  end

  private

  def confirmed_users
    User.confirmed.joins(:identity).merge(Identity.valid_identity)
  end

  def needs_update?(user)
    latest_count_time = user.latest_hourly_tweet_count&.start_time || 1.day.ago.utc
    latest_count_time < 24.hours.ago.utc
  end
end

class UpdateTwitterDataWorker
  include Sidekiq::Worker

  def perform(user_id: nil)
    if user_id
      user = User.find(user_id)
      update_user(user)
      return
    end

    confirmed_users.each do |user|
      update_user(user)
    end
  end

  private

  def update_user(user)
    Twitter::FollowersUpdater.new(user).call
    Twitter::TweetAndMetricsUpdater.new(user).call
  end

  def confirmed_users
    User.confirmed.joins(:identity).merge(Identity.valid_identity)
  end

  def needs_update?(user)
    latest_count_time = user.latest_hourly_tweet_count&.start_time || 1.day.ago.utc
    latest_count_time < 24.hours.ago.utc
  end
end

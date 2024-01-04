module Twitter
  class TweetCountsQuery
    attr_reader :user

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def this_weeks_tweets_count
      TweetHourlyCount.where('identity_id = ? AND start_time >= ?', @user.identity.id, @start_time)
                      .sum(:tweet_count)
    end

    def tweets_change_since_last_week
      this_weeks_tweets_count - last_weeks_tweets_count
    end

    def last_weeks_tweets_count
      TweetHourlyCount.where('identity_id = ? AND start_time >= ? AND start_time < ?',
                              @user.identity.id,
                              @start_time - 1.week,
                              @start_time)
                      .sum(:tweet_count)
    end

    def data_stale?
      last_updated_time = TweetHourlyCount.where(identity_id: @user.identity.id).maximum(:pulled_at)
      last_updated_time.blank? || Time.current - last_updated_time > 24.hours
    end
  end
end

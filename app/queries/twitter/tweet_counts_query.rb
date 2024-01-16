# frozen_string_literal: true

module Twitter
  class TweetCountsQuery
    attr_reader :user

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def this_weeks_tweets_count
      HourlyTweetCount.where('identity_id = ? AND start_time >= ?', @user.identity.id, @start_time)
                      .sum(:tweet_count)
    end

    def tweets_change_since_last_week
      current_week_count = this_weeks_tweets_count
      last_week_count = last_weeks_tweets_count

      return false if last_week_count.zero? # No data from last week

      current_week_count - last_week_count
    end


    def last_weeks_tweets_count
      HourlyTweetCount.where('identity_id = ? AND start_time >= ? AND start_time < ?',
                             @user.identity.id,
                             @start_time - 1.week,
                             @start_time)
                      .sum(:tweet_count)
    end

    def days_until_last_weeks_data_available
      earliest_data_date = HourlyTweetCount.where(identity_id: @user.identity.id).minimum(:start_time)
      return 7 unless earliest_data_date # If no data, assume a full week is needed.

      days_of_data = (Time.current.beginning_of_day - earliest_data_date.to_date).to_i
      [0, 14 - days_of_data].max # Return how many more days of data are needed, but not less than 0.
    end
  end
end

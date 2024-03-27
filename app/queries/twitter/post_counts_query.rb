
module Twitter
  class PostCountsQuery
    attr_reader :user, :start_time

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def tweet_count_over_available_time_period
      staggered_tweets_count_difference[:recent_count]
    end

    def tweets_change_over_available_time_period
      staggered_tweets_count_difference[:difference]
    end

    def tweet_comparison_days
      staggered_tweets_count_difference[:days_of_data]
    end

    def staggered_tweets_count_difference
      end_time = Time.current
      start_time = @start_time.to_time
      intended_days_of_data = @start_time.to_i

      recent_tweets = tweets_within_period(start_time, end_time)
      if recent_tweets.any?
        earliest_tweet_date = recent_tweets.first.twitter_created_at.to_date
        actual_days_of_data = (end_time.to_date - earliest_tweet_date).to_i + 1 # Include the start date itself

        if actual_days_of_data >= intended_days_of_data * 2
          days_of_data = intended_days_of_data
          difference = compare_tweets_count(days_of_data)
        else
          # Not enough data to calculate difference, so set to nil
          days_of_data = actual_days_of_data # Update days_of_data to reflect actual data available
          difference = nil
        end
      else
        # No tweets available for comparison
        days_of_data = 0
        difference = nil
      end

      recent_count = tweets_count_between(start_time, end_time)
      { days_of_data: days_of_data, recent_count: recent_count, difference: difference }
    end

    def tweets_within_period(start_time, end_time)
      Tweet.where(identity_id: user.identity.id)
           .where(twitter_created_at: start_time...end_time)
           .order(:twitter_created_at)
    end

    def compare_tweets_count(days)
      end_time = Time.current
      start_time_recent = end_time - days.days
      start_time_previous = start_time_recent - days.days

      recent_count = tweets_count_between(start_time_recent, end_time)
      previous_count = tweets_count_between(start_time_previous, start_time_recent)

      recent_count - previous_count
    end

    def tweets_count_between(start_time, end_time)
      Tweet.where(identity_id: user.identity.id)
           .where(twitter_created_at: start_time...end_time)
           .count
    end
  end
end
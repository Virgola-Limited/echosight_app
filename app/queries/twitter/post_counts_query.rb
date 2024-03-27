
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
      staggered_tweets_count_difference[:difference_count]
    end

    def days_of_data_in_recent_count
      staggered_tweets_count_difference[:days_of_data_in_recent_count]
    end

    def days_of_data_in_difference_count
      staggered_tweets_count_difference[:days_of_data_in_difference_count]
    end

    def staggered_tweets_count_difference
      end_time = Time.current
      intended_days_of_data = 7

      # Extend the start time further back if more than 7 days of data is being considered
      extended_start_time = [end_time - 14.days, @start_time.to_time].min

      recent_tweets = tweets_within_period(extended_start_time, end_time)
      if recent_tweets.any?
        earliest_tweet_date = recent_tweets.first.twitter_created_at.to_date
        latest_tweet_date = recent_tweets.last.twitter_created_at.to_date
        actual_days_of_data = (latest_tweet_date - earliest_tweet_date).to_i + 1 # Include the start date itself

        days_of_data_in_recent_count = [actual_days_of_data, intended_days_of_data].min
        days_of_data_in_difference_count = actual_days_of_data >= intended_days_of_data * 2 ? intended_days_of_data : 0

        if actual_days_of_data >= intended_days_of_data * 2
          difference_count = compare_tweets_count(days_of_data_in_recent_count)
        else
          difference_count = nil
        end
      else
        difference_count = nil
        days_of_data_in_recent_count = 0
        days_of_data_in_difference_count = 0
      end

      recent_count = tweets_count_between(@start_time.to_time, end_time)
      {
        recent_count: recent_count,
        difference_count: difference_count,
        days_of_data_in_recent_count: days_of_data_in_recent_count,
        days_of_data_in_difference_count: days_of_data_in_difference_count
      }
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
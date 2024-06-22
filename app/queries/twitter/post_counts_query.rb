module Twitter
  class PostCountsQuery
    attr_reader :identity, :date_range

    def initialize(identity:, date_range: '7d')
      @identity = identity
      @date_range = date_range
    end

    def tweet_count_over_available_time_period
      return '' if insufficient_data?

      staggered_tweets_count_difference[:recent_count]
    end

    def tweets_change_over_available_time_period
      return '' if insufficient_data? || insufficient_data_for_comparison?

      format_tweet_change(staggered_tweets_count_difference[:difference_count])
    end

    def days_of_data_in_recent_count
      staggered_tweets_count_difference[:days_of_data_in_recent_count]
    end

    def days_of_data_in_difference_count
      staggered_tweets_count_difference[:days_of_data_in_difference_count]
    end

    private

    def staggered_tweets_count_difference
      @staggered_tweets_count_difference ||= begin
        range_data = Twitter::DateRangeOptions.parse_date_range(date_range)
        start_time = range_data[:start_time]
        end_time = range_data[:end_time]

        extended_start_time = start_time - (end_time - start_time)

        recent_tweets = tweets_within_period(extended_start_time, end_time)
        if recent_tweets.any?
          earliest_tweet_date = recent_tweets.first.twitter_created_at.to_date
          latest_tweet_date = recent_tweets.last.twitter_created_at.to_date
          actual_days_of_data = (latest_tweet_date - earliest_tweet_date).to_i + 1 # Include the start date itself

          days_of_data_in_recent_count = [actual_days_of_data, (end_time - start_time).to_i / 1.day].min
          days_of_data_in_difference_count = actual_days_of_data >= (end_time - start_time).to_i / 1.day * 2 ? (end_time - start_time).to_i / 1.day : 0

          difference_count = actual_days_of_data >= (end_time - start_time).to_i / 1.day * 2 ? compare_tweets_count(days_of_data_in_recent_count) : nil
        else
          difference_count = nil
          days_of_data_in_recent_count = 0
          days_of_data_in_difference_count = 0
        end

        recent_count = tweets_count_between(start_time, end_time)
        {
          recent_count: recent_count,
          difference_count: difference_count,
          days_of_data_in_recent_count: days_of_data_in_recent_count,
          days_of_data_in_difference_count: days_of_data_in_difference_count
        }
      end
    end

    def insufficient_data?
      total_days_of_data < (Time.current.to_date - Twitter::DateRangeOptions.parse_date_range(date_range)[:start_time].to_date).to_i
    end

    def insufficient_data_for_comparison?
      range_data = Twitter::DateRangeOptions.parse_date_range(date_range)
      total_days_of_data < (Time.current.to_date - range_data[:start_time].to_date).to_i * 2
    end

    def total_days_of_data
      first_tweet = Tweet.where(identity_id: identity.id).order(:twitter_created_at).first
      return 0 unless first_tweet

      (Time.current.to_date - first_tweet.twitter_created_at.to_date).to_i + 1
    end

    def tweets_within_period(start_time, end_time)
      @tweets_within_period ||= {}
      @tweets_within_period[[start_time, end_time]] ||= Tweet.where(identity_id: identity.id)
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
      Tweet.where(identity_id: identity.id)
           .where(twitter_created_at: start_time...end_time)
           .count
    end

    def format_tweet_change(change)
      return change unless change
      return 'No change' if change.nil? || change.zero?

      format = change.positive? ? '%d increase' : '%d decrease'
      format % change.abs
    end
  end
end

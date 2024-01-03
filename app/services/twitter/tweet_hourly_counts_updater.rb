module Twitter
  class TweetHourlyCountsUpdater
    attr_reader :user, :start_time

    def initialize(user, start_time)
      @user = user
      @start_time = start_time
    end

    def call
      return if up_to_date?

      counts = fetch_tweet_counts
      store_hourly_counts(counts)
    end

    private

    def up_to_date?
      return false
      # Implement logic to check if the database has the complete and latest data
      # Example: Check if there's a record for the last hour
      last_count = TweetHourlyCount.where(user: @user).order(end_time: :desc).first
      last_count.present? && last_count.pulled_at > @start_time
    end

    def fetch_tweet_counts
      query = Twitter::TweetCountsQuery.new(@user, start_time)
      Rails.logger.debug('paul' + query.this_weeks_tweets_count.inspect)
      query.this_weeks_tweets_count
    end

    def store_hourly_counts(counts)
      counts['data'].each do |count_data|
        TweetHourlyCount.find_or_initialize_by(
          identity: @user.identity,
          start_time: DateTime.parse(count_data["start"]),
          end_time: DateTime.parse(count_data["end"])
        ).update(
          tweet_count: count_data["tweet_count"],
          pulled_at: Time.current
        )
      end
    end
  end
end

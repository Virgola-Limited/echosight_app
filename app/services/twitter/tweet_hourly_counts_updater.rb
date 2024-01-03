module Twitter
  class TweetHourlyCountsUpdater
    # need to discuss when we should run this
    # currently its run when the user confirms their account
    # we cant run it automatically from their public page as we hit
    # api limits
    # however we need to run it periodically so their data isnt stale
    # we could have a temporary refresh button on the page
    # notifies them when their data is ready
    # but the api limit is 5 an hour :(
    # a few active users and we max out the basic plan.
    # so we might need more basic plan licences or the pro plan
    # https://developer.twitter.com/en/docs/twitter-api/rate-limits
    # we should probably call this when the log in
    # however data will be stale if the public page is viewed and they havent logged in
    # recently
    attr_reader :user, :start_time

    def initialize(user, start_time)
      @user = user
      @start_time = start_time ? DateTime.parse(start_time) : 1.week.ago.utc

    end

    def call
      return if up_to_date?
      Rails.logger.debug('paul' + 'not up to date'.inspect)
      counts = fetch_tweet_counts
      store_hourly_counts(counts)
    end

    private

    def up_to_date?
      last_hour = Time.current.beginning_of_hour
      expected_hours = ((last_hour - @start_time) / 1.hour).round
      Rails.logger.debug('paul' + expected_hours.inspect)
      recent_counts = TweetHourlyCount.where(identity: @user.identity, start_time: @start_time..last_hour)
      Rails.logger.debug('paul recent_counts.count == expected_hours' + (recent_counts.count == expected_hours).inspect)
      recent_counts.count == expected_hours && recent_counts.all? { |count| count.pulled_at > count.end_time }
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

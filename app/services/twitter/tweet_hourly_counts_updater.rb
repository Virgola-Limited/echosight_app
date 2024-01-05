# frozen_string_literal: true

module Twitter
  class TweetHourlyCountsUpdater
    # TODO: make this a background job with these rules
    # https://developer.twitter.com/en/docs/twitter-api/rate-limits
    # use up allowance every 15 minutes
    # set clear expectations about the delays on the API
    # get the old user identities and update them
    # consider not getting data for users who haven't logged in in a while (more relaxed)
    # or nobody is visiting their public page (active public page is more important to have up to date)
    # try and update the data for the public page once every 24 hours if possible
    attr_reader :user, :start_time

    def initialize(user, start_time)
      @user = user
      @start_time = start_time ? DateTime.parse(start_time) : 1.week.ago.utc
    end

    def call
      counts = fetch_tweet_counts
      store_hourly_counts(counts)
    end

    private

    def fetch_tweet_counts
      query = Twitter::TweetCountsQuery.new(user: @user, start_time:)
      Rails.logger.debug("paul#{query.this_weeks_tweets_count.inspect}")
      query.this_weeks_tweets_count
    end

    def store_hourly_counts(counts)
      counts['data'].each do |count_data|
        TweetHourlyCount.find_or_initialize_by(
          identity: @user.identity,
          start_time: DateTime.parse(count_data['start']),
          end_time: DateTime.parse(count_data['end'])
        ).update(
          tweet_count: count_data['tweet_count'],
          pulled_at: Time.current
        )
      end
    end
  end
end

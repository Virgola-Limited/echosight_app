# frozen_string_literal: true

module Twitter

  # Currently not used might be useful if we go to the Pro plan.
  class HourlyTweetCountsUpdater
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      store_hourly_counts
    end

    private

    # TO-DO: push twitter API calls to own class
    # BASIC PLAN LIMIT GET_2_tweets_counts_recent	5/15 minutes
    def fetch_tweet_counts_from_last_week
      endpoint = 'tweets/counts/recent'
      params = {
        'query' => "from:#{user.handle}",
        'start_time' => 1.week.ago.utc.iso8601
      }

      twitter_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def twitter_client
      @twitter_client ||= Client.new.client
    end

    def store_hourly_counts
      fetch_tweet_counts_from_last_week['data'].each do |count_data|
        HourlyTweetCount.find_or_initialize_by(
          identity: user.identity,
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

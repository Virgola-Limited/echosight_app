# frozen_string_literal: true

module Twitter
  class TweetHourlyCountsUpdater
    attr_reader :user, :start_time

    def initialize(user, start_time)
      @user = user
      @start_time = start_time ? DateTime.parse(start_time) : 1.week.ago.utc
    end

    def call
      store_hourly_counts
    end

    private

    # TO-DO: push twitter API calls to own class
    def fetch_tweet_counts_from_last_week
      endpoint = 'tweets/counts/recent'
      params = {
        'query' => "from:#{user.twitter_handle}",
        'start_time' => 1.week.ago.utc.iso8601
      }

      x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def x_client
      @x_client ||= TwitterClientService.new.client
    end

    def store_hourly_counts
      fetch_tweet_counts_from_last_week['data'].each do |count_data|
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

# frozen_string_literal: true

module Twitter
  class NewTweetsFetcher
    attr_reader :user, :client, :within_time, :api_batch_id

    def initialize(user:, client: nil, within_time: ApplicationConstants::TWITTER_FETCH_INTERVAL, api_batch_id:)
      @user = user
      @client = client || SocialData::ClientAdapter.new
      @within_time = within_time
      @api_batch_id = api_batch_id
    end

    def call
      fetch_and_store_tweets
    end

    # fix this later
    def self.days_to_fetch
      14
    end

    private

    def fetch_and_store_tweets
      params = { query: "from:#{user.handle} within_time:#{within_time}" }
      tweets = client.search_tweets(params)
      today_user_data = nil

      tweets['data'].each do |tweet_data|
        today_user_data ||= tweet_data['user']['data']
        process_tweet_data(tweet_data)
      end

      if today_user_data
        IdentityUpdater.new(today_user_data).call
        @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
      end
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user, api_batch_id: api_batch_id, allow_update: false)
    end
  end
end

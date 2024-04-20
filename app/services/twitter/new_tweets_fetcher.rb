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
      metrics_created_count, tweets_updated_count = fetch_and_store_tweets
      Notifications::SlackNotifier.call(
        message: "User: #{user.identity.handle}: #{metrics_created_count} tweet metrics created, #{tweets_updated_count} tweets updated.",
        channel: :general
      )
      response_message = "Fetched and stored #{metrics_created_count} tweet metrics and updated #{tweets_updated_count} tweets.\n\n"
      response_message += @user_metrics_updated_message if @user_metrics_updated_message
      response_message
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
      metrics_created_count = 0
      tweets_updated_count = 0

      tweets['data'].each do |tweet_data|
        today_user_data ||= tweet_data['user']['data']
        metrics_created, tweet_updated = process_tweet_data(tweet_data)
        metrics_created_count += 1 if metrics_created
        tweets_updated_count += 1 if tweet_updated
      end

      if today_user_data
        @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
        IdentityUpdater.new(today_user_data).call
      end

      [metrics_created_count, tweets_updated_count]
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user, api_batch_id: @api_batch_id)
    end
  end
end

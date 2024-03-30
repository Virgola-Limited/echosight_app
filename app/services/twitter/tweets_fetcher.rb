# frozen_string_literal: true

module Twitter
  class TweetsFetcher
    attr_reader :user, :client

    DAYS_TO_FETCH = 14

    def initialize(user:, client: nil)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
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

    private

    def fetch_and_store_tweets
      params = { query: "from:#{user.handle} within_time:#{DAYS_TO_FETCH}d" }
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
      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      twitter_created_at = DateTime.parse(tweet_data['created_at'])

      tweet_updated = tweet.new_record? || tweet.changed?
      tweet.assign_attributes(
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: twitter_created_at
      )
      tweet.save! if tweet_updated

      metric_attributes = {
        retweet_count: metrics['retweet_count'].to_i,
        quote_count: metrics['quote_count'].to_i,
        like_count: metrics['like_count'].to_i,
        impression_count: metrics['impression_count'].to_i,
        reply_count: metrics['reply_count'].to_i,
        bookmark_count: metrics['bookmark_count'].to_i,
      }

      if non_public_metrics && non_public_metrics['user_profile_clicks']
        metric_attributes.merge!(
          user_profile_clicks: non_public_metrics['user_profile_clicks']
        )
      end
      tweet_metric = TweetMetric.find_or_initialize_by(tweet: tweet, pulled_at: Date.today)

      [tweet_metric.update!(metric_attributes), tweet_updated]
    end
  end
end

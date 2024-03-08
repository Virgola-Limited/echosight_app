# frozen_string_literal: true

module Twitter
  class TweetsFetcher
    attr_reader :user, :client

    def initialize(user:, client: nil)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
    end

    def call
      metrics_created_count, tweets_updated_count = fetch_and_store_tweets
      Notifications::SlackNotifier.call(
        message: "#{metrics_created_count} tweet metrics created, #{tweets_updated_count} tweets updated.",
        channel: :general
      )
      response_message = "Fetched and stored #{metrics_created_count} tweet metrics and updated #{tweets_updated_count} tweets.\n\n"
      if @user_metrics_updated_message
        response_message += @user_metrics_updated_message
      end
      response_message
    end

    private

    def fetch_and_store_tweets
      params = { query: "from:#{user.handle} within_time:7d" }
      tweets = client.search_tweets(params)

      today_user_data = nil
      metrics_created_count = 0
      tweets_updated_count = 0

      tweets['data'].each do |tweet_data|
        unless today_user_data
          today_user_data = tweet_data['user']['data']
        end

        metrics_created, tweet_updated = process_tweet_data(tweet_data)
        metrics_created_count += 1 if metrics_created
        tweets_updated_count += 1 if tweet_updated
      end
      @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call if today_user_data

      [metrics_created_count, tweets_updated_count]
    end

    def process_tweet_data(tweet_data)
      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])

      tweet_updated = tweet.new_record? || tweet.changed?
      twitter_created_at = DateTime.parse(tweet_data['created_at'])
      tweet.update!(
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: twitter_created_at
      )

      metric_attributes = {
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        impression_count: metrics['impression_count'],
        reply_count: metrics['reply_count'],
        bookmark_count: metrics['bookmark_count'],
        pulled_at: DateTime.now.utc
      }

      if non_public_metrics && non_public_metrics['user_profile_clicks']
        metric_attributes.merge!(
          user_profile_clicks: non_public_metrics['user_profile_clicks']
        )
      end

      TweetMetric.create!(metric_attributes)
      [true, tweet_updated]
    end
  end
end

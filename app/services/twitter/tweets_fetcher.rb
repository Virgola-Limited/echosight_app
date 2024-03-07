# frozen_string_literal: true

module Twitter
  class TweetsFetcher
    attr_reader :user, :client

    def initialize(user:, client: nil)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
    end

    def call
      fetch_and_store_tweets
    end

    private

    def fetch_and_store_tweets
      params = { query: "from:#{user.handle} within_time:7d" }
      tweets = client.search_tweets(params)

      # Variable to hold user data for the first tweet created today
      today_user_data = nil

      tweets['data'].each do |tweet_data|
        twitter_created_at = DateTime.parse(tweet_data['created_at'])

        # Set today_user_data for the first tweet created today
        today_user_data ||= tweet_data['user']['data'] if twitter_created_at.to_date == Date.today

        process_tweet_data(tweet_data)
      end

      return unless today_user_data
      UserMetricsUpdater.new(user: today_user_data).call
    end

    def process_tweet_data(tweet_data)
      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])

      twitter_created_at = DateTime.parse(tweet_data['created_at'])
      tweet.update(
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at:
      )

      metric_attributes = {
        tweet:,
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
    end
  end
end

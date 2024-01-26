module Twitter
  class TweetAndMetricsUpdater
    attr_reader :user, :twitter_client

    def initialize(user)
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      fetch_and_store_tweets
    end

    private

    def fetch_tweets(next_token = nil)
      response = twitter_client.fetch_user_tweets(next_token)

      if response.is_a?(Hash) && response.key?('errors')
        error_messages = response['errors'].map { |error| error['detail'] }.join(', ')
        raise StandardError, "Twitter API Error: #{error_messages}"
      end

      [response['data'] || [], response.dig('meta', 'next_token')]
    end

    def fetch_and_store_tweets
      next_token = nil
      loop do
        tweets, next_token = fetch_tweets(next_token)
        Rails.logger.debug('paul tweets' + tweets.inspect)
        break if tweets.empty?

        tweets.each do |tweet_data|
          process_tweet_data(tweet_data)
        end

        break unless next_token
      end
    end

    def process_tweet_data(tweet_data)
      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      tweet.update(
        text: tweet_data['text'],
        identity_id: user.identity.id
      )

      TweetMetric.create(
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quotes_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        impression_count: metrics['impression_count'],
        reply_count: metrics['reply_count'],
        bookmark_count: metrics['bookmark_count'],
        user_profile_clicks: non_public_metrics['user_profile_clicks'],
        pulled_at: DateTime.now.utc # Consider using user time zone
      )
    end
  end
end

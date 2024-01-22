# frozen_string_literal: true

module Twitter
  class UserTweetsUpdater
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      fetch_and_store_tweets
    end

    private

    # GET /2/users/:id
    # 500 requests / 24 hours
    # PER APP
    # 100 requests / 24 hours

    # Endpoint: GET /2/users/:id/tweets
    def fetch_tweets(next_token = nil)
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics',
        'pagination_token' => next_token,
        'max_results' => 100 # Adjust this value as needed, up to 100
      }.compact # Remove nil values
      response = x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
      [response['data'] || [], response.dig('meta', 'next_token')]
    end

    def x_client
      @x_client ||= ClientService.new.client
    end

    def fetch_and_store_tweets
      next_token = nil
      loop do
        tweets, next_token = fetch_tweets(next_token)
        break if tweets.empty?

        tweets.each do |tweet_data|
          metrics = tweet_data['public_metrics']
          tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
          tweet.update(
            text: tweet_data['text'],
            identity_id: user.identity.id
          )

          TweetCount.create(
            tweet: tweet,
            retweet_count: metrics['retweet_count'],
            quotes_count: metrics['quote_count'],
            like_count: metrics['like_count'],
            impression_count: metrics['impression_count'],
            reply_count: metrics['reply_count'],
            bookmark_count: metrics['bookmark_count'],
            pulled_at: DateTime.now.utc # could consider using the user time zone?
          )
        end

        break unless next_token
      end
    end
  end
end

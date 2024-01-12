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

    # Endpoint: GET /2/users/:id/tweets
    # Replace :id with the actual user ID
    def fetch_tweets
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics'
      }
      response = x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
      response['data'] || []
    end

    def x_client
      @x_client ||= ClientService.new.client
    end

    def fetch_and_store_tweets
      tweets = fetch_tweets

      tweets.each do |tweet_data|
        metrics = tweet_data['public_metrics']
        Tweet.find_or_initialize_by(twitter_id: tweet_data['id']).update(
          text: tweet_data['text'],
          retweet_count: metrics['retweet_count'],
          reply_count: metrics['reply_count'],
          like_count: metrics['like_count'],
          quote_count: metrics['quote_count'],
          impression_count: metrics['impression_count'],
          bookmark_count: metrics['bookmark_count'],
          identity_id: user.identity.id
        )
      end
    end
  end
end

module Twitter
  class Client
    attr_reader :user, :api

    def initialize(user = nil)
      @user = user
      @api = Twitter::Api.new(user)
    end

    def post_tweet(text)
      endpoint = 'tweets'
      params = { 'text' => text }
      api.make_api_call(endpoint, params, :oauth2)
    end

    def fetch_user_tweets(next_token = nil)
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics,non_public_metrics',
        'pagination_token' => next_token,
        'max_results' => 100
      }.compact

      api.make_api_call(endpoint, params, :oauth1)
    end

    def fetch_tweets_by_ids(tweet_ids)
      endpoint = 'tweets'
      fields = 'created_at,public_metrics'

      params = {
        'ids' => tweet_ids.join(','), # Convert to a comma-separated string
        'tweet.fields' => fields
      }

      api.make_api_call(endpoint, params, :oauth1)
    end

    def fetch_rate_limit_data
      endpoint = 'application/rate_limit_status.json'
      params = {} # Add necessary parameters if needed
      api.make_api_call(endpoint, params, :oauth2, :v1_1) # Using OAuth1 for Twitter API v1.1
    end
  end
end

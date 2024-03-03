module SocialData
  class ClientAdapter
    attr_reader :user, :social_data_client

    def initialize(user)
      @user = user
      @social_data_client = SocialData::Client.new(user)
    end

    def fetch_user_tweets(next_token = nil)
      response = social_data_client.fetch_user_tweets(next_token)
      adapt_tweets_response_format(response)
    end

    def fetch_user_with_metrics
      response = social_data_client.fetch_user_with_metrics
      adapt_user_response_format(response)
    end

    private

    def adapt_tweets_response_format(response)
      adapted_tweets = response['tweets'].map do |tweet|
        {
          'id' => tweet['id_str'],
          'text' => tweet['full_text'] || tweet['text'],
          'created_at' => tweet['tweet_created_at'],
          'public_metrics' => {
            'retweet_count' => tweet['retweet_count'],
            'reply_count' => tweet['reply_count'],
            'like_count' => tweet['favorite_count'],
            'quote_count' => tweet['quote_count']
          }
          # Add more fields as needed
        }
      end

      adapted_response = { 'data' => adapted_tweets }
      # Check if 'next_cursor' exists and add it under 'meta' key in adapted response
      adapted_response['meta'] = { 'next_token' => response['next_cursor'] } if response['next_cursor']
      adapted_response
    end

    def adapt_user_response_format(response)
      {
        "data" => {
          "id" => response["id_str"],
          "name" => response["name"],
          "username" => response["screen_name"],
          "public_metrics" => {
            "followers_count" => response["followers_count"],
            "following_count" => response["friends_count"], # Assuming following_count maps to friends_count
            "listed_count" => response["listed_count"],
            "tweet_count" => response["statuses_count"]
          }
        }
      }
    end
  end
end

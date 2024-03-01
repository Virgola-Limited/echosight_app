module SocialData
  class ClientAdapter
    attr_reader :user, :social_data_client

    def initialize(user)
      @user = user
      @social_data_client = SocialData::Client.new(user)
    end

    def fetch_user_tweets(next_token = nil)
      response = social_data_client.fetch_user_tweets(next_token)
      adapt_response_format(response)
    end

    private

    def adapt_response_format(response)
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
          },
          # Add more fields as needed
        }
      end

      { 'data' => adapted_tweets }
    end
  end
end

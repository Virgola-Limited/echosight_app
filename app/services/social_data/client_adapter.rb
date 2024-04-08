# frozen_string_literal: true

module SocialData
  class ClientAdapter
    attr_reader :user, :social_data_client

    def initialize(user: nil)
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

    def fetch_tweets_by_ids(tweet_ids)
      response = social_data_client.fetch_tweets_by_ids(tweet_ids)
      adapt_tweets_response_format(response)
    end

    def search_tweets(params = {}, single_request = false)
      response = social_data_client.search_tweets(params, single_request)
      adapt_tweets_response_format(response)
    end

    private

    def adapt_tweets_response_format(response)
      adapted_tweets = response['tweets'].map do |tweet|
        adapted_tweet = {
          'id' => tweet['id_str'],
          'text' => tweet['full_text'] || tweet['text'],
          'created_at' => tweet['tweet_created_at'],
          'public_metrics' => {
            'retweet_count' => tweet['retweet_count'],
            'reply_count' => tweet['reply_count'],
            'like_count' => tweet['favorite_count'],
            'quote_count' => tweet['quote_count'],
            'impression_count' => tweet['views_count'],
            'bookmark_count' => tweet['bookmark_count']
          },
          'is_pinned' => tweet['is_pinned'] || 'false'
        }

        # Include adapted user data in each tweet
        adapted_tweet['user'] = adapt_user_response_format(tweet['user']) if tweet['user']
        adapted_tweet
      end

      adapted_response = { 'data' => adapted_tweets }
      if response.is_a?(Hash) && response['next_cursor']
        adapted_response['meta'] =
          { 'next_token' => response['next_cursor'] }
      end
      adapted_response
    end

    def adapt_user_response_format(response)
      {
        'data' => {
          'id' => response['id_str'],
          'name' => response['name'],
          'username' => response['screen_name'],
          'public_metrics' => {
            'followers_count' => response['followers_count'],
            'following_count' => response['friends_count'],
            'listed_count' => response['listed_count'],
            'tweet_count' => response['statuses_count']
          },
          'description' => response['description'],
          'image_url' => response['profile_image_url_https'],
          'banner_url' => response['profile_banner_url']
        }
      }
    end
  end
end

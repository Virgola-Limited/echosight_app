# frozen_string_literal: true

module Twitter
  class NewTweetsFetcher
    # This also refreshes existing tweets because there is no way to know if a tweet is new or not
    # before the request and pinned tweets seem to appear in each page of responses
    # Consider renaming to make it clear that it also refreshes existing tweets
    attr_reader :user, :client, :number_of_requests

    def initialize(user:, number_of_requests:, client: nil)
      @number_of_requests = number_of_requests
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
    end

    def call
      fetch_and_store_tweets
    end

    private

    def fetch_tweets(next_token = nil)
      response = client.fetch_user_tweets(next_token)
      p response['data'].length
      p response['data'].last
      [response['data'] || [], response.dig('meta', 'next_token')]
    end

    def fetch_and_store_tweets
      next_token = nil
      counter = 0

      loop do
        break if @number_of_requests && counter >= @number_of_requests

        tweets, next_token = fetch_tweets(next_token)
        p next_token
        break if tweets.empty?

        tweets.each do |tweet_data|
          p tweet_data
          # break if Tweet.exists?(twitter_id: tweet_data['id']) # Stop if tweet is already stored

          process_tweet_data(tweet_data)
        end

        break unless next_token

        counter += 1
      end
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

      # this really needs to be an upserter to avoid wasting requests that have existing tweets
      # complete this in https://github.com/Virgola-Limited/echosight_app/pull/50/files
      TweetMetric.create(metric_attributes)
    end
  end
end

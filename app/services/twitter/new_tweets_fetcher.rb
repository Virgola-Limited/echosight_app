module Twitter
  class NewTweetsFetcher
    attr_reader :user, :twitter_client, :number_of_requests

    def initialize(user: , number_of_requests:)
      @number_of_requests = number_of_requests
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      fetch_and_store_tweets
    end

    private

    def fetch_tweets(next_token = nil)
      response = twitter_client.fetch_user_tweets(next_token)

      [response['data'] || [], response.dig('meta', 'next_token')]
    end

    def fetch_and_store_tweets
      next_token = nil
      counter = 0

      loop do
        break if @number_of_requests && counter >= @number_of_requests

        tweets, next_token = fetch_tweets(next_token)
        break if tweets.empty?

        tweets.each do |tweet_data|
          break if Tweet.exists?(twitter_id: tweet_data['id']) # Stop if tweet is already stored
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

      # Parse Twitter API timestamp and assign to twitter_created_at
      twitter_created_at = DateTime.parse(tweet_data['created_at'])
      tweet.update(
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: twitter_created_at # Assign parsed timestamp
      )

      # this really needs to be an upserter to avoid wasting requests that have existing tweets
      # complete this in https://github.com/Virgola-Limited/echosight_app/pull/50/files
      TweetMetric.create(
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
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

module Twitter
  class TweetMetricsRefresher
    attr_reader :user, :twitter_client

    def initialize(user)
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      outdated_tweet_ids = find_outdated_tweet_ids
      update_tweets_and_metrics(outdated_tweet_ids) unless outdated_tweet_ids.empty?
    end

    private

    def find_outdated_tweet_ids
      Tweet.where('updated_at < ?', 24.hours.ago).pluck(:twitter_id)
    end

    def update_tweets_and_metrics(tweet_ids)
      tweets_data = twitter_client.fetch_tweets_by_ids(tweet_ids)
      return unless tweets_data.is_a?(Hash) && tweets_data.key?('data')

      tweets_data['data'].each do |tweet_data|
        process_tweet_data(tweet_data)
      end
    end

    def process_tweet_data(tweet_data)
      tweet = Tweet.find_by(twitter_id: tweet_data['id'])
      return unless tweet

      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics'] # Adjust according to available metrics

      tweet.update(
        text: tweet_data['text'],
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      )

      # Create a new TweetMetric record for each update
      TweetMetric.create(
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        reply_count: metrics['reply_count'],
        pulled_at: DateTime.now.utc # Consider using user time zone
        # Include other metrics as needed, note that non_public_metrics might not be available
      )
    end
  end
end

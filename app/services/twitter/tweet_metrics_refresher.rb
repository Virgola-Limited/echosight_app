module Twitter
  class TweetMetricsRefresher
    attr_reader :user, :twitter_client

    BATCH_SIZE = 50
    MAX_TWEETS_TO_UPDATE = 400

    def initialize(user)
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      outdated_tweet_ids = find_outdated_tweet_ids
      outdated_tweet_ids.each_slice(BATCH_SIZE) do |batch|
        update_tweets_and_metrics(batch)
      end
    end

    private

    def find_outdated_tweet_ids
      # Select the IDs of the top MAX_TWEETS_TO_UPDATE most outdated tweets
      Tweet.order(updated_at: :asc).limit(MAX_TWEETS_TO_UPDATE).pluck(:twitter_id)
    end

    def update_tweets_and_metrics(tweet_ids)
      tweets_data = twitter_client.fetch_tweets_by_ids(tweet_ids)
      return unless tweets_data.is_a?(Hash) && tweets_data.key?('data')

      tweets_data['data'].each do |tweet_data|
        process_tweet_data(tweet_data)
      end
    end

    def process_tweet_data(tweet_data)
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])

      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']  # Adjust according to available metrics

      tweet.update(
        text: tweet_data['text'],
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      )

      TweetMetric.create(
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        impression_count: metrics['impression_count'],  # Include only if available
        reply_count: metrics['reply_count'],
        bookmark_count: metrics['bookmark_count'],  # Include only if available
        user_profile_clicks: non_public_metrics['user_profile_clicks'],  # Include only if available
        pulled_at: DateTime.now.utc  # Consider using user time zone
      )
    end
  end
end

#  Twitter::TweetMetricsRefresher.new(user).call
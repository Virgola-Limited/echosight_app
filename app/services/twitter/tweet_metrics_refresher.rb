module Twitter
  class TweetMetricsRefresher
    attr_reader :user, :client

    BATCH_SIZE = 100
    MAX_REQUESTS = 15
    UPDATABLE_TIME_FRAME = 7.days

    def initialize(user: client:)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
    end

    def call
      outdated_tweet_ids.each_slice(BATCH_SIZE).with_index do |batch, index|
        break if index >= MAX_REQUESTS - 1

        update_tweets_and_metrics(batch, include_non_public_metrics: true)
      end
    end

    private

    def outdated_tweet_ids
      user.identity.tweets
           .where('twitter_created_at > ?', UPDATABLE_TIME_FRAME)
           .where('updated_at < ?', 24.hours.ago)
           .order(updated_at: :asc)
           .pluck(:twitter_id)
    end

    def update_tweets_and_metrics(tweet_ids, include_non_public_metrics: true)
      tweets_data = client.fetch_tweets_by_ids(tweet_ids, include_non_public_metrics)

      tweets_data['data'].each do |tweet_data|
        process_tweet_data(tweet_data, include_non_public_metrics)
      end
    end

    def process_tweet_data(tweet_data, include_non_public_metrics)
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      metrics = tweet_data['public_metrics']
      tweet.touch

      metric_attributes = {
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        impression_count: metrics['impression_count'],
        reply_count: metrics['reply_count'],
        bookmark_count: metrics['bookmark_count'],
        pulled_at: DateTime.now.utc
      }

      if include_non_public_metrics
        non_public_metrics = tweet_data['non_public_metrics']
        metric_attributes.merge!(
          user_profile_clicks: non_public_metrics.fetch('user_profile_clicks', nil)  # Optional
        )
      end

      TweetMetric.create!(metric_attributes)
    end
  end
end

#  Twitter::TweetMetricsRefresher.new(user).call
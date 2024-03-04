module Twitter
  class TweetMetricsRefresher
    attr_reader :user, :client, :batch_size, :include_non_public_metrics

    UPDATABLE_TIME_FRAME = 7.days.ago

    def initialize(user:, client: nil, batch_size: 120)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
      @batch_size = batch_size
      @include_non_public_metrics = false # ask the client?
    end

    def call
      outdated_tweet_ids.each_slice(batch_size) do |batch|
        update_tweets_and_metrics(batch, include_non_public_metrics: include_non_public_metrics)
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

    def update_tweets_and_metrics(tweet_ids, include_non_public_metrics:)
      tweets_data = client.fetch_tweets_by_ids(tweet_ids, include_non_public_metrics)
      tweets_data['data'].each do |tweet_data|
        process_tweet_data(tweet_data, include_non_public_metrics)
      end
      sleep(1)
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
        metric_attributes[:user_profile_clicks] = non_public_metrics.fetch('user_profile_clicks', nil)
      end

      result = TweetMetric.create!(metric_attributes)
      result
    end
  end
end

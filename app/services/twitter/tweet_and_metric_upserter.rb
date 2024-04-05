module Twitter
  class TweetAndMetricUpserter < Services::Base
    attr_reader :tweet_data, :user

    def initialize(tweet_data:, user:)
      @tweet_data = tweet_data
      @user = user
    end

    def call
      tweet = initialize_or_update_tweet
      tweet_metric = find_or_initialize_tweet_metric(tweet)

      [update_tweet_metric(tweet_metric), tweet]
    end

    private

    def initialize_or_update_tweet
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      # if tweet.new_record?
        # Schedule the metrics update job to run 24 hours after the tweet's creation
        # Twitter::TweetMetricsUpdateJob.perform_in(24.hours, tweet.id)
      # end
      tweet.assign_attributes(tweet_attributes)
      tweet.save! if tweet.new_record? || tweet.changed?
      tweet
    end

    def tweet_attributes
      {
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      }
    end

    def find_or_initialize_tweet_metric(tweet)
      # Use a date range for today to find an existing TweetMetric or initialize a new one
      today_range = DateTime.current.beginning_of_day..DateTime.current.end_of_day
      TweetMetric.find_or_initialize_by(tweet: tweet, pulled_at: today_range)
    end

    def update_tweet_metric(tweet_metric)
      tweet_metric.assign_attributes(metric_attributes)
      tweet_metric.pulled_at = DateTime.current unless tweet_metric.persisted?
      tweet_metric.save!
    end

    def metric_attributes
      metrics = tweet_data['public_metrics']
      {
        retweet_count: metrics['retweet_count'].to_i,
        quote_count: metrics['quote_count'].to_i,
        like_count: metrics['like_count'].to_i,
        impression_count: metrics['impression_count'].to_i,
        reply_count: metrics['reply_count'].to_i,
        bookmark_count: metrics['bookmark_count'].to_i
        # Add non_public_metrics if needed
      }
    end
  end
end

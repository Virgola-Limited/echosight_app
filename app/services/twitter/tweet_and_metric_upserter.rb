module Twitter
  class TweetAndMetricUpserter < Services::Base
    attr_reader :tweet_data, :user

    def initialize(tweet_data:, user:)
      @tweet_data = tweet_data
      @user = user
    end

    def call
      metrics = tweet_data['public_metrics']
      non_public_metrics = tweet_data['non_public_metrics']
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      # if tweet.new_record?
        # Schedule the metrics update job to run 24 hours after the tweet's creation
        # Twitter::TweetMetricsUpdateJob.perform_in(24.hours, tweet.id)
      # end
      twitter_created_at = DateTime.parse(tweet_data['created_at'])

      tweet_updated = tweet.new_record? || tweet.changed?
      tweet.assign_attributes(
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: twitter_created_at
      )
      tweet.save! if tweet_updated

      metric_attributes = {
        retweet_count: metrics['retweet_count'].to_i,
        quote_count: metrics['quote_count'].to_i,
        like_count: metrics['like_count'].to_i,
        impression_count: metrics['impression_count'].to_i,
        reply_count: metrics['reply_count'].to_i,
        bookmark_count: metrics['bookmark_count'].to_i,
      }

      if non_public_metrics && non_public_metrics['user_profile_clicks']
        metric_attributes.merge!(
          user_profile_clicks: non_public_metrics['user_profile_clicks']
        )
      end
      tweet_metric = TweetMetric.find_or_initialize_by(tweet: tweet, pulled_at: DateTime.current)

      [tweet_metric.update!(metric_attributes), tweet_updated]
    end
  end
end
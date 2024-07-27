# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    include TweetMetrics::MetricsCalculation

    def likes_count
      total_metrics_for_period('like_count', date_range[:start_time], date_range[:end_time]) || ''
    end

    def likes_change_since_last_period
      change_since_last_period('like_count')
    end

    def top_tweets_for_user
      tweets_in_date_range = Tweet.where(identity_id: identity.id)
                                  .where(twitter_created_at: date_range[:start_time]..date_range[:end_time])

      tweet_metrics = TweetMetric.where(tweet_id: tweets_in_date_range)
                                 .group(:tweet_id, :pulled_at, :impression_count, :id)
                                 .where.not(impression_count: nil)
                                 .order(impression_count: :desc)

      results = []
      used_tweets = []
      tweet_metrics.each do |tweet_metric|
        if used_tweets.exclude?(tweet_metric.tweet_id)
          results << tweet_metric.id
          used_tweets << tweet_metric.tweet_id
        end
        break if used_tweets.count == 10
      end

      TweetMetric.where(id: results)
                 .includes(:tweet)
                 .order(impression_count: :desc)
    end

    def all_tweets_for_user
      tweets_in_date_range = Tweet.where(identity_id: identity.id)
                                  .where(twitter_created_at: date_range[:start_time]..date_range[:end_time])

      TweetMetric.where(tweet_id: tweets_in_date_range)
                 .where.not(impression_count: nil)
                 .includes(:tweet)
                 .order(impression_count: :desc)
    end
  end
end

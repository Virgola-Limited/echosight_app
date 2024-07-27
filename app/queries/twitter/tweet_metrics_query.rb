module Twitter
  class TweetMetricsQuery
    include TweetMetrics::MetricsCalculation

    def likes_count
      return '' if insufficient_data?

      total_metrics_for_period('like_count', date_range[:start_time], date_range[:end_time]) || ''
    end

    def likes_change_since_last_period
      change_since_last_period('like_count')
    end

    def top_tweets_for_user
      tweets_in_date_range = Tweet.where(identity_id: identity.id)
                                  .where(twitter_created_at: date_range[:start_time]..date_range[:end_time])

      tweet_metrics_subquery = TweetMetric.where(tweet_id: tweets_in_date_range)
                                          .where.not(impression_count: nil)
                                          .select('tweet_id, MAX(impression_count) AS max_impression_count')
                                          .group(:tweet_id)

      top_tweet_ids = Tweet.joins("INNER JOIN (#{tweet_metrics_subquery.to_sql}) AS tm ON tweets.id = tm.tweet_id")
                           .order('tm.max_impression_count DESC')
                           .limit(10)
                           .pluck(:id)

      Tweet.where(id: top_tweet_ids).includes(:tweet_metrics)
    end
  end
end

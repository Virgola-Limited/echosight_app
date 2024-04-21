module Twitter
  class TweetDataQuery
    def self.incomplete_user_updates(days)
      UserTwitterDataUpdate.joins(identity: :user)
                          .where(completed_at: nil)
                          .where('user_twitter_data_updates.created_at > ?', days.days.ago)
                          .order('user_twitter_data_updates.started_at DESC')
                          .limit(10)
    end

    def self.problematic_tweets
      earliest_metrics_subquery = TweetMetric.select('MIN(id) AS id')
                                            .where('created_at < ?', 26.hours.ago)
                                            .group(:tweet_id)

      Tweet.joins(:tweet_metrics)
          .where('tweet_metrics.id IN (?)', earliest_metrics_subquery)
          .where(tweet_metrics: { updated_count: [nil, 0] })
          .limit(10)
    end

    def self.tweets_needing_refresh(days)
      recent_metric_tweet_ids = TweetMetric.joins(tweet: { identity: :user })
                                          .where('tweet_metrics.updated_at >= ?', 24.hours.ago)
                                          .merge(User.syncable)
                                          .select('tweet_metrics.tweet_id')

      Tweet.joins(identity: :user)
          .merge(User.syncable)
          .where('tweets.twitter_created_at > ?', days.days.ago)
          .where.not(id: recent_metric_tweet_ids)
          .limit(10)
    end

    def self.aggregated_metrics
      TweetMetric.joins(tweet: { identity: :user })
                 .select("date(tweet_metrics.pulled_at) as day, users.id as user_id, count(*) as count")
                 .group("date(tweet_metrics.pulled_at), users.id")  # Changed here
                 .order("date(tweet_metrics.pulled_at) DESC")  # And here
                 .limit(10)
    end
  end
end
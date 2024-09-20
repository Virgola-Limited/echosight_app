module Twitter
  class TweetDataChecksQuery
    def self.incomplete_user_updates(time_ago)
      UserTwitterDataUpdate.joins(identity: :user)
                           .merge(Identity.syncable)
                           .where(completed_at: nil)
                           .where('user_twitter_data_updates.created_at > ?', time_ago)
                           .order('user_twitter_data_updates.retry_count DESC, user_twitter_data_updates.started_at DESC')
                           .limit(10)
    end

    def self.problematic_tweets
      earliest_metrics_subquery = TweetMetric.joins(tweet: {identity: :user})
                                            .select('MIN(tweet_metrics.id) AS id')
                                            .where('tweet_metrics.created_at < ?', 26.hours.ago)
                                            .merge(Identity.syncable)
                                            .group(:tweet_id)

      Tweet.joins(:tweet_metrics)
          .where('tweet_metrics.id IN (?)', earliest_metrics_subquery)
          .where(tweet_metrics: { updated_count: [nil, 0] })
          .limit(10)
    end

    def self.tweets_needing_refresh
      recent_metric_tweet_ids = TweetMetric.joins(tweet: { identity: :user })
                                           .where('tweet_metrics.updated_at >= ?', 24.hours.ago)
                                           .merge(Identity.syncable)
                                           .select('tweet_metrics.tweet_id')

      tweets = Tweet.joins(identity: :user)
                    .merge(Identity.syncable)
                    .where('tweets.twitter_created_at > ?', Tweet.max_age_for_refresh)
                    .where.not(id: recent_metric_tweet_ids)

      return [] if tweets.count <= 5

      tweets.group('users.id')
            .select('users.id, users.email, count(tweets.id) as tweet_count')
            .map do |tweet|
              { user: tweet.email, count: tweet.tweet_count }
            end
    end

    def self.aggregated_metrics
      TweetMetric.joins(tweet: { identity: :user })
                 .select("date(tweet_metrics.pulled_at) as day, users.id as user_id, count(*) as count")
                 .group("date(tweet_metrics.pulled_at), users.id")  # Ensure no typo here
                 .order("date(tweet_metrics.pulled_at) DESC")       # Ensure correct field references
                 .limit(10)
    end


    def self.users_with_no_recent_twitter_user_metrics
      # Select users with their most recent TwitterUserMetric date
      Identity.syncable
          .joins('LEFT JOIN identities ON identities.user_id = users.id')
          .joins('LEFT JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
          .select('users.id, users.email, MAX(twitter_user_metrics.updated_at) AS recent_metric_date')
          .group('users.id, users.email')
          .having('MAX(twitter_user_metrics.updated_at) < ? OR MAX(twitter_user_metrics.updated_at) IS NULL', 6.hours.ago)
          .distinct
    end
  end
end
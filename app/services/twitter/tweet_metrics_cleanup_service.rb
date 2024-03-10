module Twitter
  class TweetMetricsCleanupService
    def self.call
      new.call
    end

    def call
      Tweet.find_each do |tweet|
        tweet.tweet_metrics.pluck(Arel.sql("DISTINCT DATE(pulled_at)")).each do |date|
          # Order by pulled_at descending and then by created_at descending to ensure
          # that if there are multiple metrics with the same pulled_at timestamp,
          # the one created last is kept.
          all_metrics_for_date = tweet.tweet_metrics
                                      .where('DATE(pulled_at) = ?', date)
                                      .order(pulled_at: :desc, created_at: :desc)

          # Exclude the first one (the latest by pulled_at and then by created_at), and delete the rest
          all_metrics_for_date.offset(1).destroy_all
        end
      end
    end
  end
end

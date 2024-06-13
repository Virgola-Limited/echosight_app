# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    attr_reader :identity, :start_time

    def initialize(identity:, start_time: nil)
      @identity = identity
      @start_time = start_time || 1.week.ago.utc
    end

    def maximum_days_of_data
      start_time.to_date.upto(Date.current).count
    end

    def top_tweets_for_user
      last_seven_days_of_tweets = Tweet.where(identity_id: identity.id).where('twitter_created_at > ?',
                                                                                   start_time)

      tweet_metrics = TweetMetric.where(tweet_id: last_seven_days_of_tweets)
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

    # same as impressions_count dry up later
    def likes_count
      total_likes_for_period(7.days.ago, Time.current)
    end

    # same as impressions_change_since_last_week dry up later
    def likes_change_since_last_week
      current_week_likes = likes_count

      previous_week_likes = total_likes_for_period(14.days.ago, 7.days.ago)
      return false if previous_week_likes.zero?

      percentage_change = ((current_week_likes - previous_week_likes) / previous_week_likes.to_f) * 100
      percentage_change.round(2)
    end

    private

    # same as total_impressions_for_period dry up later
    def total_likes_for_period(start_time, end_time)
      # Collect tweet IDs that match the given conditions
      tweet_ids = Tweet.where(identity_id: identity.id,
                              twitter_created_at: start_time.beginning_of_day..end_time.end_of_day)
                       .pluck(:id)

      # If there are no matching tweet IDs, return 0 immediately to prevent SQL errors
      return 0 if tweet_ids.empty?

      query = <<-SQL
        WITH first_metrics AS (
          SELECT DISTINCT ON (tweet_id) *
          FROM tweet_metrics
          WHERE tweet_id IN (#{tweet_ids.join(', ')})
            AND pulled_at BETWEEN '#{start_time}' AND '#{end_time}'
          ORDER BY tweet_id, pulled_at
        )
        SELECT SUM(like_count) FROM first_metrics
      SQL

      ActiveRecord::Base.connection.execute(query).first['sum'].to_i
    end
  end
end

# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    include DateRangeHelper

    attr_reader :identity, :date_range

    def initialize(identity:, date_range: '7d')
      @identity = identity
      @date_range = parse_date_range(date_range)
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

    def likes_count
      return '' if insufficient_data?

      total_likes_for_period(date_range[:start_time], date_range[:end_time])
    end

    def likes_change_since_last_week
      return '' if insufficient_data? || insufficient_data_for_comparison?

      current_period_likes = likes_count

      previous_period_start_time = (date_range[:start_time] - 7.days)
      previous_period_end_time = (date_range[:end_time] - 7.days)
      previous_period_likes = total_likes_for_period(previous_period_start_time, previous_period_end_time)

      return '' if previous_period_likes.zero?

      percentage_change = ((current_period_likes - previous_period_likes) / previous_period_likes.to_f) * 100
      percentage_change.round(2)
    end

    private

    def insufficient_data?
      total_days_of_data < (Time.current.to_date - date_range[:start_time].to_date).to_i
    end

    def insufficient_data_for_comparison?
      total_days_of_data < (Time.current.to_date - date_range[:start_time].to_date).to_i * 2
    end

    def total_days_of_data
      first_tweet = Tweet.where(identity_id: identity.id).order(:twitter_created_at).first
      return 0 unless first_tweet

      (Time.current.to_date - first_tweet.twitter_created_at.to_date).to_i + 1
    end

    def total_likes_for_period(start_time, end_time)
      tweet_ids = Tweet.where(identity_id: identity.id,
                              twitter_created_at: start_time.beginning_of_day..end_time.end_of_day)
                       .pluck(:id)

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

# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      attr_reader :user, :start_time

      def initialize(user:, start_time: nil)
        @user = user
        @start_time = start_time || 1.week.ago.utc
      end

      # same as likes_count dry up later
      def impressions_count
        total_impressions_for_period(7.days.ago, Time.current)
      end

      # same as likes_change_since_last_week dry up later
      def impressions_change_since_last_week
        current_week_impressions = impressions_count

        previous_week_impressions = total_impressions_for_period(14.days.ago, 7.days.ago)
        return false if previous_week_impressions.zero?

        percentage_change = ((current_week_impressions - previous_week_impressions) / previous_week_impressions.to_f) * 100
        percentage_change.round(2)
      end

      def impression_counts_per_day
        end_time = 24.hours.ago.end_of_day
        start_time = (end_time - 6.days).beginning_of_day

        tweets_with_metrics = Tweet.includes(:tweet_metrics)
                                   .where(identity_id: user.identity.id, twitter_created_at: start_time..end_time)
                                   .order('tweet_metrics.pulled_at ASC')

        grouped_tweets = tweets_with_metrics.group_by { |tweet| tweet.twitter_created_at.to_date }

        (start_time.to_date..end_time.to_date).map do |date|
          daily_tweets = grouped_tweets[date] || []
          impressions_sum = daily_tweets.sum do |tweet|
            tweet.tweet_metrics.first.try(:impression_count) || 0
          end

          { date: date, impression_count: impressions_sum }
        end
      end

      def maximum_days_of_data
        start_time.to_date.upto(Date.current).count
      end

      private

      # same as total_likes_for_period dry up later
      def total_impressions_for_period(start_time, end_time)
        # Collect tweet IDs that match the given conditions
        tweet_ids = Tweet.where(identity_id: user.identity.id,
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
          SELECT SUM(impression_count) FROM first_metrics
        SQL

        ActiveRecord::Base.connection.execute(query).first['sum'].to_i
      end
    end
  end
end

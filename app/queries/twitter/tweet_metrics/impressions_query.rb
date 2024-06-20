# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      include DateRangeHelper

      attr_reader :identity, :date_range

      def initialize(identity:, date_range: '7d')
        @identity = identity
        @date_range = parse_date_range(date_range)
      end

      def impressions_count
        return '' if insufficient_data?

        total_impressions_for_period(date_range[:start_time], date_range[:end_time])
      end

      def impressions_change_since_last_week
        return '' if insufficient_data? || insufficient_data_for_comparison?

        current_period_impressions = impressions_count

        previous_period_start_time = (date_range[:start_time] - 7.days)
        previous_period_end_time = (date_range[:end_time] - 7.days)
        previous_period_impressions = total_impressions_for_period(previous_period_start_time, previous_period_end_time)

        return false if previous_period_impressions.zero?

        percentage_change = ((current_period_impressions - previous_period_impressions) / previous_period_impressions.to_f) * 100
        percentage_change.round(2)
      end

      def impression_counts_per_day
        start_time = date_range[:start_time]
        end_time = date_range[:end_time]

        tweets_with_metrics = Tweet.includes(:tweet_metrics)
                                   .where(identity_id: identity.id, twitter_created_at: start_time..end_time)
                                   .order('tweet_metrics.pulled_at ASC')

        grouped_tweets = tweets_with_metrics.group_by { |tweet| tweet.twitter_created_at.to_date }

        (start_time.to_date..end_time.to_date).map.with_index do |date, index|
          daily_tweets = grouped_tweets[date] || []
          impressions_sum = daily_tweets.sum { |tweet| tweet.tweet_metrics.first.try(:impression_count) || 0 }

          formatted_label = format_label(date, index)

          { date: date, data_points: impressions_sum, formatted_label: formatted_label }
        end
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

      def total_impressions_for_period(start_time, end_time)
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
          SELECT SUM(impression_count) FROM first_metrics
        SQL

        ActiveRecord::Base.connection.execute(query).first['sum'].to_i
      end
    end
  end
end

# frozen_string_literal: true

module Twitter
  module TweetMetrics
    module MetricsCalculation
      extend ActiveSupport::Concern

      included do
        include DateRangeHelper

        attr_reader :identity, :date_range
      end

      def initialize(identity:, date_range: '7d')
        @identity = identity
        @date_range = parse_date_range(date_range)
      end

      def insufficient_data?
        required_days = (date_range[:end_time] - date_range[:start_time]).to_i / 1.day
        total_days_of_data < required_days
      end

      def insufficient_data_for_comparison?
        required_days_for_comparison = 2 * (date_range[:end_time] - date_range[:start_time]).to_i / 1.day
        total_days_of_data < required_days_for_comparison
      end

      def total_days_of_data
        first_tweet = Tweet.where(identity_id: identity.id).order(:twitter_created_at).first
        return 0 unless first_tweet

        (Time.current.to_date - first_tweet.twitter_created_at.to_date).to_i + 1
      end

      def total_metrics_for_period(metric, start_time, end_time)
        tweet_ids = Tweet.where(identity_id: identity.id,
                                twitter_created_at: start_time.beginning_of_day..end_time.end_of_day)
                         .pluck(:id)

        return '' if tweet_ids.empty?

        query = <<-SQL
          WITH first_metrics AS (
            SELECT DISTINCT ON (tweet_id) *
            FROM tweet_metrics
            WHERE tweet_id IN (#{tweet_ids.join(', ')})
              AND pulled_at BETWEEN '#{start_time}' AND '#{end_time}'
            ORDER BY tweet_id, pulled_at
          )
          SELECT SUM(#{metric}) FROM first_metrics
        SQL

        result = ActiveRecord::Base.connection.execute(query).first
        result ? result['sum'].to_i : 0
      end

      def change_since_last_period(metric)
        return '' if insufficient_data? || insufficient_data_for_comparison?

        current_period_metrics = total_metrics_for_period(metric, date_range[:start_time], date_range[:end_time])

        period_length = (date_range[:end_time] - date_range[:start_time]).to_i / 1.day
        previous_period_start_time = date_range[:start_time] - period_length.days
        previous_period_end_time = date_range[:start_time] - 1.second

        previous_period_metrics = total_metrics_for_period(metric, previous_period_start_time, previous_period_end_time)

        return '' if previous_period_metrics.zero?

        percentage_change = ((current_period_metrics - previous_period_metrics) / previous_period_metrics.to_f) * 100
        percentage_change.round(2)
      end
    end
  end
end

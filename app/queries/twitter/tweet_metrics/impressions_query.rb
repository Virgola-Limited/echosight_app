# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      include MetricsCalculation

      def impressions_count
        return '' if insufficient_data?

        total_metrics_for_period('impression_count', date_range[:start_time], date_range[:end_time])
      end

      def impressions_change_since_last_period
        change_since_last_period('impression_count')
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
    end
  end
end

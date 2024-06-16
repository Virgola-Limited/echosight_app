# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class EngagementRateQuery
      attr_reader :identity, :date_range

      def initialize(identity:, date_range: '7d')
        @identity = identity
        @date_range = parse_date_range(date_range)
      end

      def engagement_rate_percentage_per_day
        end_time = date_range[:end_time]
        start_time = date_range[:start_time]

        tweets_with_metrics = Tweet.includes(:tweet_metrics)
                                   .where(identity_id: identity.id, twitter_created_at: start_time..end_time)
                                   .order('tweet_metrics.pulled_at ASC')

        date_range_dates = (start_time.to_date..end_time.to_date).to_a

        grouped_tweets = tweets_with_metrics.group_by { |tweet| tweet.twitter_created_at.to_date }

        date_range_dates.map.with_index do |date, index|
          daily_tweets = grouped_tweets[date] || []
          daily_interactions = 0
          daily_impressions = 0

          daily_tweets.each do |tweet|
            first_metric = tweet.tweet_metrics.first
            next unless first_metric

            interactions = first_metric.retweet_count.to_i + first_metric.quote_count.to_i +
                           first_metric.like_count.to_i + first_metric.reply_count.to_i +
                           first_metric.bookmark_count.to_i
            daily_interactions += interactions
            daily_impressions += first_metric.impression_count.to_i
          end

          engagement_rate = daily_impressions.positive? ? (daily_interactions.to_f / daily_impressions * 100).round(2) : 0
          formatted_label = format_label(date)

          { date: date, engagement_rate_percentage: engagement_rate, formatted_label: formatted_label }
        end
      end

      private

      def parse_date_range(range)
        end_time = Time.current.end_of_day
        start_time = case range
                     when '7d'
                       6.days.ago.beginning_of_day
                     when '14d'
                       13.days.ago.beginning_of_day
                     when '1m'
                       1.month.ago.beginning_of_day
                     when '3m'
                       3.months.ago.beginning_of_day
                     when '1y'
                       1.year.ago.beginning_of_day
                     else
                       6.days.ago.beginning_of_day
                     end
        { start_time: start_time, end_time: end_time, range: range }
      end

      def format_label(date)
        case date_range[:range]
        when '3m', '1y'
          date.day == 1 ? date.strftime('%b') : ''
        else
          date.day == 1 ? date.strftime('%b %d') : date.strftime('%d')
        end
      end
    end
  end
end

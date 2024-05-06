# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      attr_reader :user, :start_time

      def initialize(user:, start_time: nil)
        @user = user
        @start_time = start_time || 1.week.ago.utc
      end

      def impressions_count
        return 0 if user.tweet_metrics.count.zero?

        # Calculate impressions for the last 7 days and the previous 7 days
        current_week_impressions = total_impressions_for_period(7.days.ago.beginning_of_day, Time.current)
        previous_week_impressions = total_impressions_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

        # Return the difference in impressions between the last two 7-day periods
        current_week_impressions - previous_week_impressions
      end

      def impressions_change_since_last_week
        # Calculate impressions for the last 7 days and the previous 7 days
        current_week_impressions = total_impressions_for_period(7.days.ago, Time.current)
        previous_week_impressions = total_impressions_for_period(14.days.ago, 7.days.ago)

        return false if previous_week_impressions.zero? # No data from last week

        # Calculate the percentage change in impressions
        percentage_change = if previous_week_impressions.positive?
                              ((current_week_impressions - previous_week_impressions) / previous_week_impressions.to_f) * 100
                            else
                              0 # No change if both current and previous week impressions are zero
                            end
        percentage_change.round(2)
      end

      def impression_counts_per_day
        end_date = Date.current
        start_date = end_date - 6.days

        results = (start_date..end_date).map do |date|
          tweets_from_date = Tweet.where(identity_id: user.identity.id,
                                         twitter_created_at: date.beginning_of_day..date.end_of_day)

          impressions_sum = tweets_from_date.map do |tweet|
            tweet.tweet_metrics.order(pulled_at: :asc).first.try(:impression_count) || 0
          end.sum

          { date: date, impression_count: impressions_sum }
        end

        results
      end

      def maximum_days_of_data
        start_time
      end

      private

      def total_impressions_for_period(start_time, end_time)
        TweetMetric.joins(:tweet)
                   .where(tweets: { identity_id: user.identity.id })
                   .where(pulled_at: start_time..end_time)
                   .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
                   .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
                   .group_by { |tm| [tm.tweet_id, tm.pulled_at.to_date] }
                   .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).impression_count.to_i }
                   .sum
      end
    end
  end
end

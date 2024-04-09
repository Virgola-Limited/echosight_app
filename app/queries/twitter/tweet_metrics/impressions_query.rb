# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      attr_reader :user, :start_time

      def initialize(user:, start_time: nil)
        @user = user
        @start_time = start_time || 1.week.ago.utc
      end

      def first_day_impressions
        # dont use until we decide if the impression count at the top works the same as the graphs
        ''

        # grouped_metrics, sorted_dates = fetch_grouped_metrics
        # return nil if sorted_dates.empty?

        # first_date = sorted_dates.first
        # first_day_impression_count = grouped_metrics[first_date].sum(&:impression_count)

        # { date: first_date, impression_count: first_day_impression_count }
      end

      def impressions_count
        return 0 if user.tweet_metrics.count.zero?

        # Check if we have at least 14 days of data
        earliest_record_date = user.tweet_metrics.order(:pulled_at).first.pulled_at.to_date
        return false if (Date.current - earliest_record_date).to_i < 14

        # Calculate impressions for the last 7 days and the previous 7 days
        current_week_impressions = total_impressions_for_period(7.days.ago.beginning_of_day, Time.current)
        previous_week_impressions = total_impressions_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

        # Return the difference in impressions between the last two 7-day periods
        current_week_impressions - previous_week_impressions
      end

      def impressions_change_since_last_week
        # Calculate impressions for the last 7 days and the previous 7 days
        current_week_impressions = total_impressions_for_period(7.days.ago.beginning_of_day, Time.current)
        previous_week_impressions = total_impressions_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

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
        # Define the range of days for which you want to fetch the data
        end_date = Date.current # Assuming you want data up to the current date
        start_date = end_date - 6.days # Adjust this as needed

        (start_date..end_date).map do |date|
          # Fetch tweets created on 'date' and sum up their impressions from the same day
          impressions_sum = TweetMetric.joins(:tweet)
                                       .where(tweets: { identity_id: user.identity.id,
                                                        twitter_created_at: date.beginning_of_day..date.end_of_day })
                                       .where('tweet_metrics.pulled_at::date = ?', date)
                                       .sum(:impression_count)

          { date:, impression_count: impressions_sum }
        end
      end

      # Old version not used
      # def impression_counts_per_day_old
      #   grouped_metrics, sorted_dates = fetch_grouped_metrics(number_of_days:  8)
      #   daily_total_impressions = calculate_total_impressions(grouped_metrics, sorted_dates)

      #   # Calculate daily impression differences, excluding the first day
      #   sorted_dates.each_cons(2).map do |previous_date, current_date|
      #     difference = daily_total_impressions[current_date] - daily_total_impressions[previous_date]
      #     { date: current_date, impression_count: difference } # Replace negative differences with 0
      #   end
      # end
      # Old version not used

      def maximum_days_of_data
        start_time
      end

      private

      ############
      # Old version not used
      # def calculate_total_impressions(grouped_metrics, sorted_dates)
      #   # Initialize a hash to keep track of total impressions per day
      #   daily_total_impressions = {}
      #   sorted_dates.each do |date|
      #     daily_total_impressions[date] = grouped_metrics[date].sum { |metric| metric.impression_count || 0 }
      #   end
      #   daily_total_impressions
      # end

      # def fetch_grouped_metrics(number_of_days: nil)
      #   pulled_at_date_time = number_of_days&.days&.ago || start_time
      #   # Fetch the latest TweetMetric record for each day for each tweet
      #   tweet_metrics = TweetMetric.select('DISTINCT ON (tweet_id, DATE(pulled_at)) *')
      #                              .joins(:tweet)
      #                              .where('pulled_at > ?', pulled_at_date_time)
      #                              .where(tweets: { identity_id: user.identity.id })
      #                              .order('tweet_id, DATE(pulled_at), pulled_at DESC')

      #   # Group the metrics by date and sort the dates
      #   grouped_metrics = tweet_metrics.group_by { |metric| metric.pulled_at.to_date }
      #   sorted_dates = grouped_metrics.keys.sort

      #   [grouped_metrics, sorted_dates]
      # end

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

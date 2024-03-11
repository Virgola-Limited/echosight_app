module Twitter
  module TweetMetrics
    class ProfileClicksQuery
      def initialize
        raise "Not used"
      end

      def profile_clicks_count
        if user.tweet_metrics.count.zero?
          return 0
        end
        # Check if we have at least 14 days of data
        earliest_record_date = user.tweet_metrics.order(:pulled_at).first.pulled_at.to_date
        return false if (Date.current - earliest_record_date).to_i < 14

        # Calculate profile clicks for the last 7 days and the previous 7 days
        current_week_clicks = total_profile_clicks_for_period(7.days.ago.beginning_of_day, Time.current)
        previous_week_clicks = total_profile_clicks_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

        # Return the difference in profile clicks between the last two 7-day periods
        current_week_clicks - previous_week_clicks
      end


      def profile_clicks_change_since_last_week
        # Calculate profile clicks for the last 7 days and the previous 7 days
        current_week_clicks = total_profile_clicks_for_period(7.days.ago.beginning_of_day, Time.current)
        previous_week_clicks = total_profile_clicks_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

        return false if previous_week_clicks.zero? # No data from last week

        # Calculate the percentage change in profile clicks
        percentage_change = if previous_week_clicks.positive?
                              ((current_week_clicks - previous_week_clicks) / previous_week_clicks.to_f) * 100
                            else
                              0 # No change if both current and previous week clicks are zero
                            end
        percentage_change.round(2)
      end

          def profile_clicks_count_per_day(days_ago = 28)
      raise 'Cant use without twitter api'
      TweetMetric.joins(:tweet)
                 .where(tweets: { identity_id: user.identity.id })
                 .where('tweet_metrics.pulled_at >= ?', days_ago.days.ago)
                 .select('DATE(tweet_metrics.pulled_at) as pulled_date, MAX(tweet_metrics.user_profile_clicks) as profile_clicks')
                 .group('DATE(tweet_metrics.pulled_at)')
                 .order('DATE(tweet_metrics.pulled_at)')
                 .pluck('DATE(tweet_metrics.pulled_at)', 'MAX(tweet_metrics.user_profile_clicks)')
                 .to_h { |date, clicks| [date.to_date, clicks] }
    end

private


def total_profile_clicks_for_period(start_time, end_time)
  TweetMetric.joins(:tweet)
    .where(tweets: { identity_id: user.identity.id })
    .where(pulled_at: start_time..end_time)
    .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
    .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
    .group_by { |tm| [tm.tweet_id, tm.pulled_at.to_date] }
    .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).user_profile_clicks.to_i }
    .sum
end
    end
  end
end
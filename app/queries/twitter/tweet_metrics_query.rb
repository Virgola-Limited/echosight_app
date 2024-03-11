# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    attr_reader :user

    MAXIMUM_DAYS_OF_DATA = 7

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def self.maximum_days_of_data
      MAXIMUM_DAYS_OF_DATA
    end

    def tweet_count_over_available_time_period
      staggered_tweets_count_difference[:recent_count]
    end

    def tweets_change_over_available_time_period
      staggered_tweets_count_difference[:difference]
    end

    def tweet_comparison_days
      staggered_tweets_count_difference[:comparison_days]
    end

    def staggered_tweets_count_difference
      days_of_data = (Time.current - @start_time.to_time) / 1.day
      comparison_days = determine_comparison_days(days_of_data)
      Rails.logger.debug('paul days_of_data' + days_of_data.inspect)

      end_time = Time.current
      start_time_recent = end_time - comparison_days.days

      recent_count = tweets_count_between(start_time_recent, end_time)
      difference = compare_tweets_count(comparison_days)

      { recent_count: recent_count, difference: difference, comparison_days: comparison_days }
    end

    def days_until_last_weeks_data_available
      earliest_data_date = HourlyTweetCount.where(identity_id: @user.identity.id).minimum(:start_time)
      return 7 unless earliest_data_date # If no data, assume a full week is needed.

      days_of_data = (Time.current.beginning_of_day - earliest_data_date.to_date).to_i
      Rails.logger.debug('pauldays_of_data' + days_of_data.inspect)
      [0, 14 - days_of_data].max # Return how many more days of data are needed, but not less than 0.
    end

    def impressions_count
      if user.tweet_metrics.count.zero?
        return 0
      end
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

    def top_tweets_for_user
      last_seven_days_of_tweets = Tweet.where(identity_id: user.identity.id).where('twitter_created_at > ?', 7.days.ago)

      tweet_metrics = TweetMetric.where(tweet_id: last_seven_days_of_tweets)
      .group(:tweet_id, :pulled_at, :impression_count, :id)
      .where.not(impression_count: nil)
      .select('*, MAX(impression_count) as max_impression_count')
      .order(impression_count: :desc)

      results = []
      used_tweets = []
      tweet_metrics.each do |tweet_metric|
        if used_tweets.exclude?(tweet_metric.tweet_id)
          results << tweet_metric
          used_tweets << tweet_metric.tweet_id
        end
        break if used_tweets.count == 5
      end

      results
    end

    def likes_count
      if user.tweet_metrics.count.zero?
        return 0
      end
      # Check if we have at least 14 days of data
      earliest_record_date = user.tweet_metrics.order(:pulled_at).first.pulled_at.to_date
      return false if (Date.current - earliest_record_date).to_i < 14

      # Calculate likes for the last 7 days and the previous 7 days
      current_week_likes = TweetMetric.joins(:tweet)
                                      .where(tweets: { identity_id: user.identity.id })
                                      .where('tweet_metrics.pulled_at >= ?', 7.days.ago)
                                      .sum(:like_count)
      previous_week_likes = TweetMetric.joins(:tweet)
                                        .where(tweets: { identity_id: user.identity.id })
                                        .where('tweet_metrics.pulled_at >= ? AND tweet_metrics.pulled_at < ?', 14.days.ago, 7.days.ago)
                                        .sum(:like_count)

      # Return the difference in likes between the last two 7-day periods
      current_week_likes - previous_week_likes
    end

    def likes_change_since_last_week
      # Calculate likes for the last 7 days and the previous 7 days
      current_week_likes = TweetMetric.joins(:tweet)
                                      .where(tweets: { identity_id: user.identity.id })
                                      .where('tweet_metrics.pulled_at >= ?', 7.days.ago)
                                      .sum(:like_count)
      previous_week_likes = TweetMetric.joins(:tweet)
                                        .where(tweets: { identity_id: user.identity.id })
                                        .where('tweet_metrics.pulled_at >= ? AND tweet_metrics.pulled_at < ?', 14.days.ago, 7.days.ago)
                                        .sum(:like_count)

      return false if previous_week_likes.zero? # No data from last week

      # Calculate the percentage change in likes
      percentage_change = if previous_week_likes.positive?
                            ((current_week_likes - previous_week_likes) / previous_week_likes.to_f) * 100
                          else
                            0 # No change if both current and previous week likes are zero
                          end
      percentage_change.round(2)
                        end

    def impression_counts_per_day
      # Subquery to select the latest TweetMetric record for each day
      subquery = TweetMetric.select('DISTINCT ON (tweet_id, DATE(pulled_at)) *')
                            .where('pulled_at > ?', MAXIMUM_DAYS_OF_DATA.days.ago)
                            .order('tweet_id, DATE(pulled_at), pulled_at DESC')

      # Inner query to calculate the daily impression count using window function
      inner_query = TweetMetric.from(subquery, :latest_metrics)
                               .joins('INNER JOIN tweets ON tweets.id = latest_metrics.tweet_id')
                               .where(tweets: { identity_id: user.identity.id })
                               .select("
                                 DATE(latest_metrics.pulled_at) as pulled_date,
                                 latest_metrics.impression_count,
                                 LAG(latest_metrics.impression_count, 1, 0) OVER (PARTITION BY latest_metrics.tweet_id ORDER BY latest_metrics.pulled_at) AS previous_impression_count
                               ")

      # Outer query to filter and sum the daily impression differences
      outer_query = TweetMetric.from("(#{inner_query.to_sql}) as impression_diffs")
                               .select('pulled_date, impression_count - previous_impression_count AS daily_impression_diff')
                               .where('impression_count - previous_impression_count > 0')

      # Final aggregation by date
      TweetMetric.from("(#{outer_query.to_sql}) as final_diffs")
                 .group('pulled_date')
                 .order('pulled_date')
                 .pluck('pulled_date', 'SUM(daily_impression_diff)')
    end

    def engagement_rate_percentage_per_day
      tweets_table = Tweet.arel_table
      tweet_metrics_table = TweetMetric.arel_table
      identities_table = Identity.arel_table

      tweets_with_engagement = Tweet.joins(:tweet_metrics)
                                    .joins(:identity)
                                    .where(identities_table[:user_id].eq(user.id))
                                    .where(tweets_table[:twitter_created_at].gt(MAXIMUM_DAYS_OF_DATA.days.ago))
                                    .where(tweets_table[:twitter_created_at].gteq(@start_time))
                                    .select(
                                      tweets_table[:twitter_created_at].as('date'),
                                      Arel.sql('SUM(tweet_metrics.retweet_count + tweet_metrics.quote_count + tweet_metrics.like_count + tweet_metrics.reply_count + tweet_metrics.user_profile_clicks + tweet_metrics.bookmark_count) as interactions'),
                                      Arel.sql('SUM(tweet_metrics.impression_count) as impressions')
                                    )
                                    .group('date')

      # Map over the ActiveRecord Relation to calculate engagement rates
      tweets_with_engagement.map do |record|
        date = record.date
        interactions = record.interactions.to_f
        impressions = record.impressions.to_f
        engagement_rate_percentage = impressions.zero? ? 0.0 : (interactions / impressions) * 100

        { date: date, engagement_rate_percentage: engagement_rate_percentage.round(2) }
      end.sort_by { |record| record[:date] }
    end


    private

    def determine_comparison_days(days_of_data)
      case days_of_data
      when 2..3
        1
      when 4..5
        2
      when 6..13
        (days_of_data / 2).floor
      else
        7
      end
    end

    def compare_tweets_count(days)
      end_time = Time.current
      start_time_recent = end_time - days.days
      start_time_previous = start_time_recent - days.days

      recent_count = tweets_count_between(start_time_recent, end_time)
      previous_count = tweets_count_between(start_time_previous, start_time_recent)

      recent_count - previous_count
    end

    def tweets_count_between(start_time, end_time)
      Tweet.where(identity_id: user.identity.id)
           .where(twitter_created_at: start_time...end_time)
           .count
    end

    # Helper method to format the created_at timestamp for grouping by date
    def grouping_date
      ->(table) { Arel::Nodes::NamedFunction.new('DATE', [table[:created_at]]) }
    end

    def last_weeks_tweets_count
      start_of_last_week = 1.week.ago.beginning_of_week
      end_of_last_week = 1.week.ago.end_of_week

      # Query the Tweet table using twitter_created_at within the last week's range
      Tweet.where(identity_id: user.identity.id)
           .where(twitter_created_at: start_of_last_week..end_of_last_week)
           .count
    end


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

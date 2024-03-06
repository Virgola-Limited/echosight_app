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
      tweets_table = Tweet.arel_table

      # Define SQL for individual max count metrics
      metrics_sql = <<-SQL
        MAX(tweet_metrics.retweet_count) AS retweet_count,
        MAX(tweet_metrics.quote_count) AS quote_count,
        MAX(tweet_metrics.like_count) AS like_count,
        MAX(tweet_metrics.reply_count) AS reply_count,
        MAX(tweet_metrics.user_profile_clicks) AS user_profile_clicks,
        MAX(tweet_metrics.bookmark_count) AS bookmark_count,
        MAX(tweet_metrics.impression_count) AS impression_count
      SQL

      # Select raw data without engagement rate calculation
      query = Tweet.joins(:tweet_metrics)
                   .where(tweets_table[:identity_id].eq(user.identity.id))
                   .where(tweets_table[:created_at].gt(MAXIMUM_DAYS_OF_DATA.days.ago))
                   .select("tweets.*, #{metrics_sql}")
                   .group(tweets_table[:id])
                   .order('MAX(tweet_metrics.impression_count) DESC')
                   .limit(5)

      # Convert the query to an array of tweets to calculate the engagement rate in Ruby
      top_tweets = query.to_a
      top_tweets.each do |tweet|
        interactions = tweet.retweet_count.to_f +
                       tweet.quote_count.to_f +
                       tweet.like_count.to_f +
                       tweet.reply_count.to_f +
                       tweet.user_profile_clicks.to_f +
                       tweet.bookmark_count.to_f
        impressions = tweet.impression_count.to_f

        # Calculate engagement rate in Ruby
        tweet.engagement_rate_percentage = if impressions.zero?
                                             0.0
                                           else
                                             (interactions / impressions) * 100
                                           end.round(2)
      end


      # Return the modified tweets with the engagement rate calculated
      top_tweets
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

      # Define the subquery to select the latest tweet metric record per tweet per day
      latest_metrics_subquery = TweetMetric.select(
        tweet_metrics_table[:tweet_id],
        tweet_metrics_table[:id].maximum.as('max_id')
      ).group(
        tweet_metrics_table[:tweet_id],
        grouping_date.call(tweet_metrics_table) # Apply grouping_date directly to the Arel table
      ).to_sql # Convert to SQL string

      # Use the subquery in a JOIN clause with a raw SQL string
      latest_metrics_join_clause = "INNER JOIN (#{latest_metrics_subquery}) latest_metrics_per_day ON tweet_metrics.id = latest_metrics_per_day.max_id"

      tweets_with_engagement = Tweet.joins(:tweet_metrics)
                                    .where('tweets.twitter_created_at > ?', MAXIMUM_DAYS_OF_DATA.days.ago)
                                    .joins(latest_metrics_join_clause) # Join using the subquery
                                    .joins(:identity) # Join with identities to access the user
                                    .where(identities_table[:user_id].eq(user.id)) # Use the user_id from the identities table
                                    .where(tweets_table[:created_at].gteq(@start_time))
                                    .select(
                                      grouping_date.call(tweets_table).as('date'), # Apply grouping_date directly to the Arel table
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

    def profile_clicks_count_per_day(days_ago = 28)
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

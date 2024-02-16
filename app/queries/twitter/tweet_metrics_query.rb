# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    attr_reader :user

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def this_weeks_tweets_count
      # Calculate the start of this week up to the current moment
      start_of_this_week = Time.current.beginning_of_week

      # Query the Tweet table using twitter_created_at from the start of this week to now
      Tweet.where(identity_id: user.identity.id)
           .where(twitter_created_at: start_of_this_week..Time.current)
           .count
    end

    def tweets_change_since_last_week
      current_week_count = this_weeks_tweets_count
      last_week_count = last_weeks_tweets_count

      return false if last_week_count.zero? # No data from last week

      current_week_count - last_week_count
    end

    def days_until_last_weeks_data_available
      earliest_data_date = HourlyTweetCount.where(identity_id: @user.identity.id).minimum(:start_time)
      return 7 unless earliest_data_date # If no data, assume a full week is needed.

      days_of_data = (Time.current.beginning_of_day - earliest_data_date.to_date).to_i
      [0, 14 - days_of_data].max # Return how many more days of data are needed, but not less than 0.
    end

    # should this be the last 7 days?
    def impressions_count
      TweetMetric.joins(:tweet)
      .where(tweets: { identity_id: user.identity.id })
      .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
      .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
      .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
      .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).impression_count.to_i }
      .sum
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
                   .where(tweets_table[:created_at].gt(28.days.ago)) # Check only the last 28 days of tweets
                   .select("tweets.*, #{metrics_sql}")
                   .group(tweets_table[:id])
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

      # Sort tweets by engagement rate percentage in descending order
      top_tweets.sort_by! { |tweet| -tweet.impression_count }

      # Return the modified tweets with the engagement rate calculated
      top_tweets
    end


    def impressions_change_since_last_week
      current_week_impressions = total_impressions_for_period(7.days.ago.beginning_of_day, Time.current)
      previous_week_impressions = total_impressions_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

      return false if previous_week_impressions.zero? # No data from last week

      if previous_week_impressions.positive?
        percentage_change = ((current_week_impressions - previous_week_impressions) / previous_week_impressions.to_f) * 100
        percentage_change.round(2)
      else
        0 # No change if both current and previous week impressions are zero
      end
    end

    def profile_clicks_count
      TweetMetric.joins(:tweet)
                 .where(tweets: { identity_id: user.identity.id })
                 .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
                 .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
                 .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
                 .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).user_profile_clicks.to_i }
                 .sum
    end

    def profile_clicks_change_since_last_week
      current_week_clicks = total_profile_clicks_for_period(7.days.ago.beginning_of_day, Time.current)
      previous_week_clicks = total_profile_clicks_for_period(14.days.ago.beginning_of_day, 7.days.ago.end_of_day)

      return false if previous_week_clicks.zero? # No data from last week

      if previous_week_clicks.positive?
        percentage_change = ((current_week_clicks - previous_week_clicks) / previous_week_clicks.to_f) * 100
        percentage_change.round(2)
      else
        0 # No change if both current and previous week clicks are zero
      end
    end

    def last_impression_counts_per_day
      TweetMetric.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .select('DATE(tweet_metrics.pulled_at) as pulled_date, MAX(tweet_metrics.impression_count) as impression_count')
                .group('DATE(tweet_metrics.pulled_at)')
                .order('DATE(tweet_metrics.pulled_at)')
                .pluck('DATE(tweet_metrics.pulled_at)', 'MAX(tweet_metrics.impression_count)')
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
                                    .where('tweets.twitter_created_at > ?', 28.days.ago)
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
      end
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
                 .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
                 .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).user_profile_clicks.to_i }
                 .sum
    end

    def total_impressions_for_period(start_time, end_time)
      TweetMetric.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .where(pulled_at: start_time..end_time)
                .sum(:impression_count)
    end
  end
end

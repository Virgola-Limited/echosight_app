# frozen_string_literal: true

# Might delete this or rename it
# need to think about HourlyTweetCounts over TweetMetric data

module Twitter
  class TweetMetricsQuery
    attr_reader :user, :tweet_id

    def initialize(user:, start_time: nil, tweet_id: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
      @tweet_id = tweet_id
    end

    def this_weeks_tweets_count
      HourlyTweetCount.where('identity_id = ? AND start_time >= ?', @user.identity.id, @start_time)
                      .sum(:tweet_count)
    end

    def tweets_change_since_last_week
      current_week_count = this_weeks_tweets_count
      last_week_count = last_weeks_tweets_count

      return false if last_week_count.zero? # No data from last week

      current_week_count - last_week_count
    end


    def last_weeks_tweets_count
      HourlyTweetCount.where('identity_id = ? AND start_time >= ? AND start_time < ?',
                             @user.identity.id,
                             @start_time - 1.week,
                             @start_time)
                      .sum(:tweet_count)
    end

    def days_until_last_weeks_data_available
      earliest_data_date = HourlyTweetCount.where(identity_id: @user.identity.id).minimum(:start_time)
      return 7 unless earliest_data_date # If no data, assume a full week is needed.

      days_of_data = (Time.current.beginning_of_day - earliest_data_date.to_date).to_i
      [0, 14 - days_of_data].max # Return how many more days of data are needed, but not less than 0.
    end

    def impressions_count
      if tweet_id
        sum_last_tweet_counts_per_day_for_tweet(tweet_id)
      else
        sum_last_tweet_counts_per_day_for_all_user_tweets
      end
    end

    def top_tweets_for_user
      tweets_table = Tweet.arel_table
      tweet_counts_table = TweetMetric.arel_table

      # Define SQL for total engagement
      total_engagement_sql = <<-SQL
        COALESCE(MAX(tweet_metrics.retweet_count), 0) +
        COALESCE(MAX(tweet_metrics.quotes_count), 0) +
        COALESCE(MAX(tweet_metrics.like_count), 0) +
        COALESCE(MAX(tweet_metrics.quote_count), 0) +
        COALESCE(MAX(tweet_metrics.impression_count), 0) +
        COALESCE(MAX(tweet_metrics.reply_count), 0) +
        COALESCE(MAX(tweet_metrics.bookmark_count), 0) AS total_engagement
      SQL

      # Define SQL for individual max count metrics
      metrics_sql = <<-SQL
        MAX(tweet_metrics.retweet_count) AS retweet_count,
        MAX(tweet_metrics.quotes_count) AS quotes_count,
        MAX(tweet_metrics.like_count) AS like_count,
        MAX(tweet_metrics.quote_count) AS quote_count,
        MAX(tweet_metrics.impression_count) AS impression_count,
        MAX(tweet_metrics.reply_count) AS reply_count
      SQL

      Tweet.joins(:tweet_metrics)
           .where(tweets_table[:identity_id].eq(user.identity.id))
           .select("tweets.*, #{total_engagement_sql}, #{metrics_sql}")
           .group(tweets_table[:id])
           .order(Arel.sql('total_engagement DESC'))
           .limit(5)
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

    private


    def total_profile_clicks_for_period(start_time, end_time)
      TweetMetric.joins(:tweet)
                 .where(tweets: { identity_id: user.identity.id })
                 .where(pulled_at: start_time..end_time)
                 .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
                 .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
                 .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
                 .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).user_profile_clicks }
                 .sum
    end

    def total_impressions_for_period(start_time, end_time)
      TweetMetric.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .where(pulled_at: start_time..end_time)
                .sum(:impression_count)
    end


    def sum_last_tweet_counts_per_day_for_tweet(tweet_id)
      TweetMetric.where(tweet_id: tweet_id)
                .group("DATE(pulled_at)")
                .order("DATE(pulled_at), pulled_at DESC")
                .pluck("DISTINCT ON (DATE(pulled_at)) impression_count")
                .map(&:to_i)
                .sum
    end

    def sum_last_tweet_counts_per_day_for_all_user_tweets
      TweetMetric.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .select('DISTINCT ON (tweet_metrics.tweet_id, DATE(tweet_metrics.pulled_at)) tweet_metrics.*')
                .order('tweet_metrics.tweet_id', Arel.sql('DATE(tweet_metrics.pulled_at)'), 'tweet_metrics.pulled_at DESC')
                .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
                .map { |_, tweet_metrics| tweet_metrics.max_by(&:pulled_at).impression_count.to_i }
                .sum
    end

  end
end

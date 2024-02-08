# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    attr_reader :user, :tweet_id

    def initialize(user:, start_time: nil, tweet_id: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
      @tweet_id = tweet_id
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

    def impressions_count
      if tweet_id
        sum_last_tweet_counts_per_day_for_tweet(tweet_id)
      else
        sum_last_tweet_counts_per_day_for_all_user_tweets
      end
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
      top_tweets.sort_by! { |tweet| -tweet.engagement_rate_percentage }

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

    # Fetches the sum of the most recent retweet counts for all tweets of the user
    def total_retweets
      # Define a subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the retweet_count from these latest TweetMetric records
      total_retweets = TweetMetric
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.retweet_count')

      total_retweets
    end

    # Fetches the sum of the most recent reply counts for all tweets of the user
    def total_replies
      # Reuse the subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the reply_count from these latest TweetMetric records
      total_replies = TweetMetric
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.reply_count')

      total_replies
    end

    def total_likes
      # Reuse the subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the like_count from these latest TweetMetric records
      total_likes = TweetMetric
                      .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                      .sum('latest_tweet_counts.like_count')

      total_likes
    end

    def profile_clicks_count_per_day
      TweetMetric.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .where('tweet_metrics.pulled_at >= ?', 30.days.ago) # Adjust the range as needed
                .select('DATE(tweet_metrics.pulled_at) as pulled_date, MAX(tweet_metrics.user_profile_clicks) as profile_clicks')
                .group('DATE(tweet_metrics.pulled_at)')
                .order('DATE(tweet_metrics.pulled_at)')
                .pluck('DATE(tweet_metrics.pulled_at)', 'MAX(tweet_metrics.user_profile_clicks)')
                .to_h { |date, clicks| [date.to_date, clicks] }
    end


    private


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

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
      days_of_data = ((Time.current - @start_time.to_time) / 1.day).to_i
      comparison_days = determine_comparison_days(days_of_data)

      end_time = Time.current
      start_time_recent = end_time - comparison_days.days

      recent_count = tweets_count_between(start_time_recent, end_time)
      difference = compare_tweets_count(comparison_days)

      { recent_count:, difference:, comparison_days: }
    end

    def days_until_last_weeks_data_available
      earliest_data_date = HourlyTweetCount.where(identity_id: @user.identity.id).minimum(:start_time)
      return 7 unless earliest_data_date # If no data, assume a full week is needed.

      days_of_data = (Time.current.beginning_of_day - earliest_data_date.to_date).to_i
      [0, 14 - days_of_data].max # Return how many more days of data are needed, but not less than 0.
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

    def top_tweets_for_user
      last_seven_days_of_tweets = Tweet.where(identity_id: user.identity.id).where('twitter_created_at > ?',
                                                                                   MAXIMUM_DAYS_OF_DATA.days.ago)

      tweet_metrics = TweetMetric.where(tweet_id: last_seven_days_of_tweets)
                                 .group(:tweet_id, :pulled_at, :impression_count, :id)
                                 .where.not(impression_count: nil)
                                #  .select('*, MAX(impression_count) as max_impression_count')
                                 .order(impression_count: :desc)

      results = []
      used_tweets = []
      tweet_metrics.each do |tweet_metric|
        if used_tweets.exclude?(tweet_metric.tweet_id)
          results << tweet_metric.id
          used_tweets << tweet_metric.tweet_id
        end
        break if used_tweets.count == 5
      end

      TweetMetric.where(id: results)
      .includes(:tweet)
      .order(impression_count: :desc)
    end

    def likes_count
      return 0 if user.tweet_metrics.count.zero?

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
      grouped_metrics, sorted_dates = fetch_grouped_metrics(number_of_days:  8)
      daily_total_impressions = calculate_total_impressions(grouped_metrics, sorted_dates)

      # Calculate daily impression differences, excluding the first day
      daily_impression_diffs = sorted_dates.each_cons(2).map do |previous_date, current_date|
        difference = daily_total_impressions[current_date] - daily_total_impressions[previous_date]
        {date: current_date, impression_count: difference} # Replace negative differences with 0
      end
      daily_impression_diffs
    end

    def first_day_impressions
      grouped_metrics, sorted_dates = fetch_grouped_metrics
      return nil if sorted_dates.empty?

      first_date = sorted_dates.first
      first_day_impression_count = grouped_metrics[first_date].sum(&:impression_count)

      { date: first_date, impression_count: first_day_impression_count }
    end


    def engagement_rate_percentage_per_day
      recent_tweets = Tweet.includes(:tweet_metrics)
                           .where(identity_id: @user.identity.id)
                           .where('tweet_metrics.pulled_at' => 8.days.ago.utc.to_date..1.day.ago.utc.to_date)
                           .references(:tweet_metrics)
      daily_engagement_rates = {}

      # Cache pulled_at dates for all metrics in a hash for quick access
      tweet_metrics_by_date = recent_tweets.each_with_object({}) do |tweet, hash|
        hash[tweet.id] = tweet.tweet_metrics.each_with_object({}) do |metric, h|
          h[metric.pulled_at] = metric
        end
      end

      # Iterate over the last 7 days
      (1..7).each do |day_ago|
        current_day = day_ago.days.ago.utc.to_date
        previous_day = (day_ago + 1).days.ago.utc.to_date

        # Initialize counters
        daily_interactions = 0
        daily_impressions = 0
        eligible_tweets_count = 0

        # Iterate over cached tweet metrics
        tweet_metrics_by_date.each do |tweet_id, metrics|
          current_metrics = metrics[current_day]
          previous_metrics = metrics[previous_day]

          # Skip if metrics are not present for both days or if any of the counts are nil
          next if current_metrics.nil? || previous_metrics.nil?
          next if [current_metrics.retweet_count, current_metrics.quote_count, current_metrics.like_count,
                   current_metrics.reply_count, current_metrics.bookmark_count, current_metrics.impression_count,
                   previous_metrics.retweet_count, previous_metrics.quote_count, previous_metrics.like_count,
                   previous_metrics.reply_count, previous_metrics.bookmark_count, previous_metrics.impression_count].any?(&:nil?)

          # Calculate differences
          interactions_difference = (current_metrics.retweet_count + current_metrics.quote_count +
                                     current_metrics.like_count + current_metrics.reply_count +
                                     current_metrics.bookmark_count) -
                                    (previous_metrics.retweet_count + previous_metrics.quote_count +
                                     previous_metrics.like_count + previous_metrics.reply_count +
                                     previous_metrics.bookmark_count)

          impressions_difference = current_metrics.impression_count - previous_metrics.impression_count

          # Avoid division by zero
          next unless impressions_difference.positive?

          daily_interactions += interactions_difference
          daily_impressions += impressions_difference
          eligible_tweets_count += 1
        end

        # Calculate and store the average engagement rate for the day if we have eligible tweets
        if eligible_tweets_count.positive?
          daily_engagement_rates[current_day] = (daily_interactions.to_f / daily_impressions * 100).round(2)
        end
      end

      # Sort and format the result
      sorted_daily_engagement_rates = daily_engagement_rates.sort_by { |date, _| date }.to_h
      sorted_daily_engagement_rates.map { |date, rate| { date: date, engagement_rate_percentage: rate } }
    end

    private

    def fetch_grouped_metrics(number_of_days: nil)
      number_of_days = number_of_days || MAXIMUM_DAYS_OF_DATA
      # Fetch the latest TweetMetric record for each day for each tweet
      tweet_metrics = TweetMetric.select('DISTINCT ON (tweet_id, DATE(pulled_at)) *')
                                 .joins(:tweet)
                                 .where('pulled_at > ?', number_of_days.days.ago)
                                 .where(tweets: { identity_id: user.identity.id })
                                 .order('tweet_id, DATE(pulled_at), pulled_at DESC')

      # Group the metrics by date and sort the dates
      grouped_metrics = tweet_metrics.group_by { |metric| metric.pulled_at.to_date }
      sorted_dates = grouped_metrics.keys.sort

      [grouped_metrics, sorted_dates]
    end

    def calculate_total_impressions(grouped_metrics, sorted_dates)
      # Initialize a hash to keep track of total impressions per day
      daily_total_impressions = {}
      sorted_dates.each do |date|
        daily_total_impressions[date] = grouped_metrics[date].sum(&:impression_count)
      end
      daily_total_impressions
    end

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

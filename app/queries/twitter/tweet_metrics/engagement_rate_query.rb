# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class EngagementRateQuery
      attr_reader :user, :start_time

      def initialize(user:, start_time: nil)
        @user = user
        @start_time = start_time || 1.week.ago.utc
      end

      def engagement_rate_percentage_per_day
        recent_tweets = Tweet.includes(:tweet_metrics)
                             .where(identity_id: @user.identity.id)
                             .where('tweet_metrics.pulled_at' => 8.days.ago.utc.to_date..Date.today)
                             .references(:tweet_metrics)
        daily_engagement_rates = {}

        # Cache pulled_at dates for all metrics in a hash for quick access
        tweet_metrics_by_date = recent_tweets.each_with_object({}) do |tweet, hash|
          hash[tweet.id] = tweet.tweet_metrics.each_with_object({}) do |metric, h|
            h[metric.pulled_at] = metric
          end
        end

        earliest_date = recent_tweets.minimum('tweet_metrics.pulled_at').to_date
        latest_date = recent_tweets.maximum('tweet_metrics.pulled_at').to_date

        # Calculate the number of days between the earliest and latest dates
        total_days = (latest_date - earliest_date).to_i

        # Iterate dynamically based on the available data range
        (0..total_days).each do |day_ago|
          current_day = day_ago.days.ago.utc.to_date
          previous_day = (day_ago + 1).days.ago.utc.to_date

          # Initialize counters
          daily_interactions = 0
          daily_impressions = 0
          eligible_tweets_count = 0

          # Iterate over cached tweet metrics
          tweet_metrics_by_date.each_value do |metrics|
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
        sorted_daily_engagement_rates.map { |date, rate| { date:, engagement_rate_percentage: rate } }
      end
    end
  end
end
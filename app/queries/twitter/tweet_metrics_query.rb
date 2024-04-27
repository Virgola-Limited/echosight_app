# frozen_string_literal: true

module Twitter
  class TweetMetricsQuery
    attr_reader :user, :start_time

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc
    end

    def maximum_days_of_data
      start_time
    end

    def top_tweets_for_user
      last_seven_days_of_tweets = Tweet.where(identity_id: user.identity.id).where('twitter_created_at > ?',
                                                                                   start_time)

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
  end
end

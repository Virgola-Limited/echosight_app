# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class EngagementRateQuery
      attr_reader :user

      def initialize(user:)
        @user = user
      end

      def engagement_rate_percentage_per_day
        end_date = Date.current
        start_date = end_date - 6.days

        date_range = (start_date..end_date)

        # Load all tweets and their metrics in one go
        tweets_with_metrics = Tweet.includes(:tweet_metrics)
                                   .where(identity_id: user.identity.id, twitter_created_at: date_range)
                                   .order('tweet_metrics.pulled_at ASC')

        date_range.map do |date|
          daily_tweets = tweets_with_metrics.select { |tweet| tweet.twitter_created_at.to_date == date }
          daily_interactions = 0
          daily_impressions = 0

          daily_tweets.each do |tweet|
            first_metric = tweet.tweet_metrics.first
            next unless first_metric

            interactions = first_metric.retweet_count.to_i + first_metric.quote_count.to_i +
                           first_metric.like_count.to_i + first_metric.reply_count.to_i +
                           first_metric.bookmark_count.to_i
            daily_interactions += interactions
            daily_impressions += first_metric.impression_count.to_i
          end

          engagement_rate = daily_impressions.positive? ? (daily_interactions.to_f / daily_impressions * 100).round(2) : 0
          { date: date, engagement_rate_percentage: engagement_rate }
        end
      end
    end
  end
end
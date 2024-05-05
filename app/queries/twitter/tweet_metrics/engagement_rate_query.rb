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

        (start_date..end_date).map do |date|
          tweets_from_date = Tweet.where(identity_id: user.identity.id,
                                         twitter_created_at: date.beginning_of_day..date.end_of_day)

          daily_interactions = 0
          daily_impressions = 0

          tweets_from_date.each do |tweet|
            first_metric = tweet.tweet_metrics.order(pulled_at: :asc).first
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
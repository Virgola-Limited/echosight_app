# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class EngagementRateQuery
      attr_reader :user, :start_time

      def initialize(user:)
        @user = user
      end

      def engagement_rate_percentage_per_day
        # Define the range of days for which you want to fetch the data
        end_date = Date.current # Assuming you want data up to the current date
        start_date = end_date - 6.days # Adjust this as needed

        (start_date..end_date).map do |date|
          # Fetch tweets created and their metrics on 'date'
          tweets_metrics_on_date = Tweet.joins(:tweet_metrics)
                                        .where(identity_id: user.identity.id, twitter_created_at: date.beginning_of_day..date.end_of_day)
                                        .where('tweet_metrics.pulled_at' => date.beginning_of_day..date.end_of_day)

          # .references(:tweet_metrics)

          daily_interactions = 0
          daily_impressions = 0
          # p tweets_metrics_on_date
          tweets_metrics_on_date.each do |tweet|
            tweet.tweet_metrics.each do |metric|
              interactions = metric.retweet_count.to_i + metric.quote_count.to_i +
                             metric.like_count.to_i + metric.reply_count.to_i +
                             metric.bookmark_count.to_i
              daily_interactions += interactions
              # p daily_interactions
              daily_impressions += metric.impression_count.to_i
              # p daily_impressions
            end
          end

          # Calculate the engagement rate for the day
          engagement_rate = daily_impressions.positive? ? (daily_interactions.to_f / daily_impressions * 100).round(2) : 0

          { date:, engagement_rate_percentage: engagement_rate }
        end
      end
    end
  end
end

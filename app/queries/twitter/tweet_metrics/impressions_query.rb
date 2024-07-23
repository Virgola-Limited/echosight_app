# frozen_string_literal: true

module Twitter
  module TweetMetrics
    class ImpressionsQuery
      include MetricsCalculation

      def impressions_count
        return '' if insufficient_data?

        total_metrics_for_period('impression_count', date_range[:start_time], date_range[:end_time])
      end

      def impressions_change_since_last_period
        change_since_last_period('impression_count')
      end

      def impression_counts_per_day
        start_time = date_range[:start_time]
        end_time = date_range[:end_time].yesterday  # Use yesterday as the end date

        tweets_with_metrics = Tweet.includes(:tweet_metrics)
                                  .where(identity_id: identity.id, twitter_created_at: start_time..end_time)
                                  .order('tweet_metrics.pulled_at ASC')

        grouped_tweets = tweets_with_metrics.group_by { |tweet| tweet.twitter_created_at.to_date }

        (start_time.to_date..end_time.to_date).map.with_index do |date, index|
          daily_tweets = grouped_tweets[date] || []
          impressions_sum = daily_tweets.sum { |tweet| tweet.tweet_metrics.first.try(:impression_count) || 0 }

          formatted_label = format_label(date, index)

          { date: date, data_points: impressions_sum, formatted_label: formatted_label }
        end
      end

      def aggregated_metrics_for_all_identities
        start_time = date_range[:start_time]
        end_time = date_range[:end_time]

        # Subquery to get the first tweet_metric for each tweet
        subquery = TweetMetric.select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.tweet_id, tweet_metrics.impression_count AS first_impression_count, tweet_metrics.retweet_count AS first_retweet_count, tweet_metrics.like_count AS first_like_count, tweet_metrics.quote_count AS first_quote_count, tweet_metrics.reply_count AS first_reply_count, tweet_metrics.bookmark_count AS first_bookmark_count')
                              .where('tweet_metrics.created_at BETWEEN ? AND ?', start_time, end_time)
                              .order('tweet_metrics.tweet_id, tweet_metrics.created_at ASC')

        Tweet.joins("INNER JOIN (#{subquery.to_sql}) AS first_metrics ON tweets.id = first_metrics.tweet_id")
             .where(twitter_created_at: start_time..end_time)
             .group('tweets.identity_id')
             .select('tweets.identity_id,
                      SUM(first_metrics.first_impression_count) AS total_impressions,
                      SUM(first_metrics.first_retweet_count) AS total_retweets,
                      SUM(first_metrics.first_like_count) AS total_likes,
                      SUM(first_metrics.first_quote_count) AS total_quotes,
                      SUM(first_metrics.first_reply_count) AS total_replies,
                      SUM(first_metrics.first_bookmark_count) AS total_bookmarks')
      end
    end
  end
end

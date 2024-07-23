# frozen_string_literal: true

module Twitter
  class LeaderboardQuery
    attr_reader :date_range

    def initialize(date_range: '7d')
      @date_range = date_range
      @start_date = self.class.start_date_for_period(date_range)
    end

    def identity_leaderboard
      metrics_data = aggregated_metrics_for_all_identities

      leaderboard_data = metrics_data.map do |data|
        identity = Identity.find(data.identity_id)

        {
          id: identity.id,
          handle: identity.handle,
          image_data: identity.image_data,
          total_impressions: data.total_impressions,
          total_retweets: data.total_retweets,
          total_likes: data.total_likes,
          total_quotes: data.total_quotes,
          total_replies: data.total_replies,
          total_bookmarks: data.total_bookmarks,
          total_followers: identity.twitter_user_metrics.maximum(:followers_count),
          engagement_rate: calculate_engagement_rate(data)
        }
      end

      leaderboard_data.select { |data| data[:total_impressions].positive? }
                      .sort_by { |data| -data[:total_impressions] }
                      .first(25)
    end

    def snapshot
      # check queries and fix them

      # subquery = Tweet.joins(:tweet_metrics)
      #                 .where('tweet_metrics.created_at >= ?', start_date)
      #                 .group('tweets.identity_id')
      #                 .select('tweets.identity_id,
      #                          COALESCE(SUM(tweet_metrics.impression_count), 0) AS total_impressions,
      #                          COALESCE(SUM(tweet_metrics.retweet_count), 0) AS total_retweets,
      #                          COALESCE(SUM(tweet_metrics.like_count), 0) AS total_likes,
      #                          COALESCE(SUM(tweet_metrics.quote_count), 0) AS total_quotes,
      #                          COALESCE(SUM(tweet_metrics.reply_count), 0) AS total_replies,
      #                          COALESCE(SUM(tweet_metrics.bookmark_count), 0) AS total_bookmarks')

      # results = Identity.joins("LEFT JOIN (#{subquery.to_sql}) AS tweet_data ON tweet_data.identity_id = identities.id")
      #                   .joins('LEFT JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
      #                   .select('identities.id AS identity_id,
      #                            identities.handle AS handle,
      #                            identities.image_data AS image_data,
      #                            tweet_data.total_impressions AS total_impressions,
      #                            tweet_data.total_retweets AS total_retweets,
      #                            tweet_data.total_likes AS total_likes,
      #                            tweet_data.total_quotes AS total_quotes,
      #                            tweet_data.total_replies AS total_replies,
      #                            tweet_data.total_bookmarks AS total_bookmarks,
      #                            MAX(twitter_user_metrics.followers_count) AS total_followers,
      #                            (COALESCE(tweet_data.total_retweets, 0) + COALESCE(tweet_data.total_likes, 0) + COALESCE(tweet_data.total_quotes, 0) + COALESCE(tweet_data.total_replies, 0) + COALESCE(tweet_data.total_bookmarks, 0)) / NULLIF(COALESCE(tweet_data.total_impressions, 0)::FLOAT, 0) * 100 AS engagement_rate')
      #                   .where('tweet_data.total_impressions > 0')
      #                   .group('identities.id, identities.handle, identities.image_data, tweet_data.total_impressions, tweet_data.total_retweets, tweet_data.total_likes, tweet_data.total_quotes, tweet_data.total_replies, tweet_data.total_bookmarks')
      #                   .order('tweet_data.total_impressions DESC')

      # results
    end

    def aggregated_metrics_for_all_identities
      start_time = parsed_date_range[:start_time]
      end_time = parsed_date_range[:end_time]

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

    private

    # def self.start_date_for_period(date_range)
    #   start_date = PERIODS.fetch(date_range, PERIODS['7_days']).call

    #   if date_range == 'today'
    #     tweets_today = Tweet.where('created_at >= ?', Time.current.beginning_of_day)
    #     start_date = 1.day.ago.beginning_of_day if tweets_today.empty?
    #   end

    #   start_date
    # end


    def calculate_engagement_rate(metrics)
      total_interactions = metrics.total_retweets + metrics.total_likes + metrics.total_quotes + metrics.total_replies + metrics.total_bookmarks
      (total_interactions.to_f / metrics.total_impressions) * 100
    end

    def parsed_date_range
      @parsed_date_range ||= Twitter::DateRangeOptions.parse_date_range(date_range)
    end


  end
end

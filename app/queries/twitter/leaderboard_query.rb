module Twitter
  class LeaderboardQuery
    attr_reader :date_range

    def initialize(date_range: '7d')
      @date_range = date_range
      @start_date = self.class.start_date_for_period(date_range)
    end

    def identity_leaderboard
      generate_leaderboard(25)
    end

    def identity_leaderboard_snapshot
      generate_leaderboard(nil)
    end

    def aggregated_metrics_for_all_identities
      start_time = parsed_date_range[:start_time]
      end_time = parsed_date_range[:end_time]

      subquery = TweetMetric.select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.tweet_id, tweet_metrics.impression_count AS first_impression_count, tweet_metrics.retweet_count AS first_retweet_count, tweet_metrics.like_count AS first_like_count, tweet_metrics.quote_count AS first_quote_count, tweet_metrics.reply_count AS first_reply_count, tweet_metrics.bookmark_count AS first_bookmark_count')
                            .where('tweet_metrics.created_at BETWEEN ? AND ?', start_time, end_time)
                            .order('tweet_metrics.tweet_id, tweet_metrics.created_at ASC')

      Rails.logger.info "Subquery SQL: #{subquery.to_sql}"

      results = Tweet.joins("INNER JOIN (#{subquery.to_sql}) AS first_metrics ON tweets.id = first_metrics.tweet_id")
                     .where(twitter_created_at: start_time..end_time)
                     .group('tweets.identity_id')
                     .select('tweets.identity_id,
                              SUM(first_metrics.first_impression_count) AS total_impressions,
                              SUM(first_metrics.first_retweet_count) AS total_retweets,
                              SUM(first_metrics.first_like_count) AS total_likes,
                              SUM(first_metrics.first_quote_count) AS total_quotes,
                              SUM(first_metrics.first_reply_count) AS total_replies,
                              SUM(first_metrics.first_bookmark_count) AS total_bookmarks')

      Rails.logger.info "Aggregated Results: #{results.to_a}"

      results
    end

    private

    def generate_leaderboard(limit)
      metrics_data = aggregated_metrics_for_all_identities

      leaderboard_data = metrics_data.map do |data|
        identity = Identity.find(data.identity_id)

        {
          identity_id: identity.id,
          handle: identity.handle,
          image_data: identity.image_data,
          total_impressions: data.total_impressions,
          total_retweets: data.total_retweets,
          total_likes: data.total_likes,
          total_quotes: data.total_quotes,
          total_replies: data.total_replies,
          total_bookmarks: data.total_bookmarks,
          total_followers: identity.twitter_user_metrics.maximum(:followers_count),
          engagement_rate: calculate_engagement_rate(data),
          rank: nil # will be set later
        }
      end

      sorted_data = leaderboard_data.select { |data| data[:total_impressions].positive? }
                                    .sort_by { |data| -data[:total_impressions] }

      if limit
        sorted_data.first(limit).each_with_index do |entry, index|
          entry[:rank] = index + 1
        end
      else
        sorted_data.each_with_index do |entry, index|
          entry[:rank] = index + 1
        end
      end

      sorted_data
    end

    def calculate_engagement_rate(metrics)
      total_interactions = metrics.total_retweets + metrics.total_likes + metrics.total_quotes + metrics.total_replies + metrics.total_bookmarks
      (total_interactions.to_f / metrics.total_impressions) * 100
    end

    def parsed_date_range
      @parsed_date_range ||= Twitter::DateRangeOptions.parse_date_range(date_range)
    end

    def self.start_date_for_period(date_range)
      case date_range
      when '24h'
        1.day.ago
      else
        # Handle other date ranges
      end
    end
  end
end

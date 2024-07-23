# frozen_string_literal: true

module Twitter
  class LeaderboardQuery
    attr_reader :date_range

    def initialize(date_range: '7d')
      @date_range = date_range
    end

    def identity_leaderboard
      metrics_query = Twitter::TweetMetrics::ImpressionsQuery.new(identity: nil, date_range: date_range)
      metrics_data = metrics_query.aggregated_metrics_for_all_identities

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

    private

    def calculate_engagement_rate(metrics)
      total_interactions = metrics.total_retweets + metrics.total_likes + metrics.total_quotes + metrics.total_replies + metrics.total_bookmarks
      (total_interactions.to_f / metrics.total_impressions) * 100
    end

    def parsed_date_range
      @parsed_date_range ||= Twitter::DateRangeOptions.parse_date_range(date_range)
    end
  end
end

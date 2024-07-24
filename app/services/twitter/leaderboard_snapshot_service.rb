module Twitter
  class LeaderboardSnapshotService
    def self.call
      today = Date.current
      ActiveRecord::Base.transaction do
        return if LeaderboardSnapshot.exists?(captured_at: today)

        snapshot = LeaderboardSnapshot.create!(captured_at: today)
        query_results = Twitter::LeaderboardQuery.new(date_range: '24h').identity_leaderboard_snapshot

        Rails.logger.info "Query Results: #{query_results.inspect}"

        query_results.each do |entry|
          snapshot.leaderboard_entries.create!(
            identity_id: entry[:identity_id],
            rank: entry[:rank],
            impressions: entry[:total_impressions],
            retweets: entry[:total_retweets],
            likes: entry[:total_likes],
            quotes: entry[:total_quotes],
            replies: entry[:total_replies],
            bookmarks: entry[:total_bookmarks]
          )
        end

        NotifyLeaderboardChangeJob.perform_async
      end
    end
  end
end

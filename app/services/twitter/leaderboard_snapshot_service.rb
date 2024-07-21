module Twitter
  class LeaderboardSnapshotService
    def self.capture_snapshots
      today = Date.current
      ActiveRecord::Base.transaction do
        next if LeaderboardSnapshot.exists?(captured_at: today)

        snapshot = LeaderboardSnapshot.create!(captured_at: today)
        query_results = Twitter::LeaderboardQuery.new.snapshot

        query_results.each_with_index do |entry, index|
          snapshot.leaderboard_entries.create!(
            identity_id: entry.identity_id,
            rank: index + 1,
            impressions: entry.total_impressions,
            retweets: entry.total_retweets,
            likes: entry.total_likes,
            quotes: entry.total_quotes,
            replies: entry.total_replies,
            bookmarks: entry.total_bookmarks
          )
        end
      end

      NotifyLeaderboardChangeJob.perform_async
    end
  end
end

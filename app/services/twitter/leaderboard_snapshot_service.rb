# app/services/twitter/leaderboard_snapshot_service.rb
module Twitter
  class LeaderboardSnapshotService
    def self.capture_snapshots
      LeaderboardController::PERIODS.keys.each do |date_range|
        snapshot = LeaderboardSnapshot.create!(date_range: date_range, captured_at: Time.current)
        Twitter::LeaderboardQuery.new(date_range: date_range).call.each_with_index do |entry, index|
          snapshot.leaderboard_entries.create!(
            identity: entry.identity,
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
    end
  end
end

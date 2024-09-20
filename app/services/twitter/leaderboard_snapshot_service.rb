module Twitter
  class LeaderboardSnapshotService
    def self.call
      today = Date.current
      changes_made = false

      ActiveRecord::Base.transaction do
        snapshot = LeaderboardSnapshot.find_or_create_by!(captured_at: today)
        query_results = Twitter::LeaderboardQuery.new(date_range: '24h').identity_leaderboard_snapshot

        Rails.logger.info "Query Results: #{query_results.inspect}"

        query_results.each do |entry|
          leaderboard_entry = snapshot.leaderboard_entries.find_or_initialize_by(identity_id: entry[:identity_id])
          leaderboard_entry.assign_attributes(
            rank: entry[:rank],
            impressions: entry[:total_impressions],
            retweets: entry[:total_retweets],
            likes: entry[:total_likes],
            quotes: entry[:total_quotes],
            replies: entry[:total_replies],
            bookmarks: entry[:total_bookmarks]
          )
          if leaderboard_entry.changed?
            leaderboard_entry.save!
            changes_made = true
          end
        end

        NotifyLeaderboardChangeJob.perform_async if changes_made
      end
    end
  end
end

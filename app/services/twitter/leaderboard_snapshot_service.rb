# app/services/twitter/leaderboard_snapshot_service.rb
module Twitter
  class LeaderboardSnapshotService
    def self.capture_snapshots
      today = Date.current
      Twitter::LeaderboardQuery::PERIODS.keys.each do |date_range|
        ActiveRecord::Base.transaction do
          next if LeaderboardSnapshot.exists?(date_range: date_range, captured_at: today)

          snapshot = LeaderboardSnapshot.create!(date_range: date_range, captured_at: today)
          query_results = Twitter::LeaderboardQuery.new(date_range: date_range).snapshot

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
      end
    end
  end
end


# Now we have our leaderboard entries we need do something with the information.

#   I'd like a service that run after a successful completion of this service:

#   # app/services/twitter/leaderboard_snapshot_service.rb
#   module Twitter
#     class LeaderboardSnapshotService
#       def self.capture_snapshots
#         today = Date.current
#         Twitter::LeaderboardQuery::PERIODS.keys.each do |date_range|
#           ActiveRecord::Base.transaction do
#             next if LeaderboardSnapshot.exists?(date_range: date_range, captured_at: today)

#             snapshot = LeaderboardSnapshot.create!(date_range: date_range, captured_at: today)
#             query_results = Twitter::LeaderboardQuery.new(date_range: date_range).snapshot

#             query_results.each_with_index do |entry, index|
#               snapshot.leaderboard_entries.create!(
#                 identity_id: entry.identity_id,
#                 rank: index + 1,
#                 impressions: entry.total_impressions,
#                 retweets: entry.total_retweets,
#                 likes: entry.total_likes,
#                 quotes: entry.total_quotes,
#                 replies: entry.total_replies,
#                 bookmarks: entry.total_bookmarks
#               )
#             end
#           end
#         end
#       end
#     end
#   end


#   service should run in the background from a job.

#   It's a high levels service that will run a
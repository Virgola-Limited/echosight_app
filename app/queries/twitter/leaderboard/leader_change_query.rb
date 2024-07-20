# app/queries/twitter/leaderboard/leader_change_query.rb
module Twitter
  module Leaderboard
    class LeaderChangeQuery
      def initialize
        @today_snapshot = LeaderboardSnapshot.find_by(captured_at: Date.current)
        @yesterday_snapshot = LeaderboardSnapshot.find_by(captured_at: Date.yesterday)
      end

      def call
        return unless @today_snapshot && @yesterday_snapshot

        today_leader = find_leader(@today_snapshot)
        yesterday_leader = find_leader(@yesterday_snapshot)

        if today_leader && yesterday_leader && today_leader.identity_id != yesterday_leader.identity_id
          {
            previous_leader: {
              twitter_handle: yesterday_leader.identity.handle,
              uid: yesterday_leader.identity.id
            },
            new_leader: {
              twitter_handle: today_leader.identity.handle,
              uid: today_leader.identity.id
            }
          }
        end
      end

      private

      def find_leader(snapshot)
        snapshot.leaderboard_entries.find_by(rank: 1)
      end
    end
  end
end

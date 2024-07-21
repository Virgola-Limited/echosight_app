# app/queries/twitter/leaderboard/new_top_ten_entries_query.rb
module Twitter
  module Leaderboard
    class NewTopTenEntriesQuery
      def initialize
        @today_snapshot = LeaderboardSnapshot.find_by(captured_at: Date.current)
        @yesterday_snapshot = LeaderboardSnapshot.find_by(captured_at: Date.yesterday)
      end

      def call
        return unless @today_snapshot && @yesterday_snapshot

        today_top_ten = top_ten(@today_snapshot)
        yesterday_top_ten_ids = top_ten(@yesterday_snapshot).map(&:identity_id)

        new_top_ten = today_top_ten.reject do |entry|
          yesterday_top_ten_ids.include?(entry.identity_id)
        end

        format_new_top_ten(new_top_ten)
      end

      private

      def top_ten(snapshot)
        snapshot.leaderboard_entries.where('rank <= 10').order(:rank)
      end

      def format_new_top_ten(entries)
        entries.map do |entry|
          {
            twitter_handle: entry.identity.handle,
            uid: entry.identity.id,
            rank: entry.rank
          }
        end
      end
    end
  end
end

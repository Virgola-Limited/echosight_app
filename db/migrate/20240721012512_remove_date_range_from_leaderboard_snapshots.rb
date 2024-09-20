class RemoveDateRangeFromLeaderboardSnapshots < ActiveRecord::Migration[7.1]
  def change
    remove_column :leaderboard_snapshots, :date_range, :string
  end
end

class ChangeCapturedAtInLeaderboardSnapshotsToDate < ActiveRecord::Migration[7.1]
  def up
    change_column :leaderboard_snapshots, :captured_at, :date
  end

  def down
    change_column :leaderboard_snapshots, :captured_at, :datetime
  end
end

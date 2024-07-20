class CreateLeaderboardSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :leaderboard_snapshots do |t|
      t.string :date_range, null: false
      t.datetime :captured_at, null: false

      t.timestamps
    end
  end
end

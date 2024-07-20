class CreateLeaderboardEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :leaderboard_entries do |t|
      t.references :leaderboard_snapshot, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true
      t.integer :rank, null: false
      t.integer :impressions, null: false
      t.integer :retweets
      t.integer :likes
      t.integer :quotes
      t.integer :replies
      t.integer :bookmarks

      t.timestamps
    end
  end
end

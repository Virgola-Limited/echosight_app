class RenameTwitterFollowerCountsToTwitterFollowersCount < ActiveRecord::Migration[7.1]
  def change
    rename_table :twitter_follower_counts, :twitter_followers_count
  end
end

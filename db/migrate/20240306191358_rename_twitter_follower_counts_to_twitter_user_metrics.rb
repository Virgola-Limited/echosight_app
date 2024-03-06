class RenameTwitterFollowerCountsToTwitterUserMetrics < ActiveRecord::Migration[7.1]
  def change
    rename_table :twitter_followers_counts, :twitter_user_metrics
  end
end

class RenameTwitterFollowerCountsToTwitterUserMetrics < ActiveRecord::Migration[7.1]
  def change
  # Comment out due prod scheme out of sync with dev
  #   rename_table :twitter_followers_counts, :twitter_user_metrics
  end
end

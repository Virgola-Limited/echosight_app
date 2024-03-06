class RenameTwitterFollowerCountsToTwitterUserMetric < ActiveRecord::Migration[7.1]
  def change
    rename_table :twitter_user_metrics, :twitter_user_metrics
  end
end

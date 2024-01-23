class RenameTweetCountsToTweetMetrics < ActiveRecord::Migration[7.1]
  def change
    rename_table :tweet_counts, :tweet_metrics
  end
end

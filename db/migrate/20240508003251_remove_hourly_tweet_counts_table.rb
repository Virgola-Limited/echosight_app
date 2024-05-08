class RemoveHourlyTweetCountsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :hourly_tweet_counts
  end
end

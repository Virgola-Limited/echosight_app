class RenameHourlyTweetCountTable < ActiveRecord::Migration[7.1]
  def change
    rename_table :tweet_hourly_counts, :hourly_tweet_counts
  end
end

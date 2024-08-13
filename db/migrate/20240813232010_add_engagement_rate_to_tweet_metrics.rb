class AddEngagementRateToTweetMetrics < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_metrics, :engagement_rate, :float
  end
end

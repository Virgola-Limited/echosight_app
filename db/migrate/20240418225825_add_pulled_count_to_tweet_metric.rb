class AddPulledCountToTweetMetric < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_metrics, :pulled_count, :integer
  end
end

class AddUpdatedCountToTweetMetrics < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_metrics, :updated_count, :integer, default: 0, null: false
  end
end

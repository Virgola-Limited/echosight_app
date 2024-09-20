class ChangePulledAtToDateInTweetMetrics < ActiveRecord::Migration[7.1]
  def change
    change_column :tweet_metrics, :pulled_at, :date
  end
end

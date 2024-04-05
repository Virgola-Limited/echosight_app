class ChangePulledAtToDatetimeInTweetMetrics < ActiveRecord::Migration[7.1]
  def up
    change_column :tweet_metrics, :pulled_at, :datetime
  end

  def down
    change_column :tweet_metrics, :pulled_at, :date
  end
end

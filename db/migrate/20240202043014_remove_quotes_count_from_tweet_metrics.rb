class RemoveQuotesCountFromTweetMetrics < ActiveRecord::Migration[7.1]
  def up
    remove_column :tweet_metrics, :quotes_count
  end

  def down
    add_column :tweet_metrics, :quotes_count, :integer
  end
end

class SetDefaultsForTweetMetrics < ActiveRecord::Migration[7.1]
  def up
    # Update existing records
    TweetMetric.where(impression_count: nil).update_all(impression_count: 0)
    TweetMetric.where(like_count: nil).update_all(like_count: 0)
    TweetMetric.where(retweet_count: nil).update_all(retweet_count: 0)
    TweetMetric.where(quote_count: nil).update_all(quote_count: 0)
    TweetMetric.where(reply_count: nil).update_all(reply_count: 0)
    TweetMetric.where(bookmark_count: nil).update_all(bookmark_count: 0)

    # Change columns to not null and set default
    change_column :tweet_metrics, :impression_count, :integer, default: 0, null: false
    change_column :tweet_metrics, :like_count, :integer, default: 0, null: false
    change_column :tweet_metrics, :retweet_count, :integer, default: 0, null: false
    change_column :tweet_metrics, :quote_count, :integer, default: 0, null: false
    change_column :tweet_metrics, :reply_count, :integer, default: 0, null: false
    change_column :tweet_metrics, :bookmark_count, :integer, default: 0, null: false
  end

  def down
    # Revert columns to allow null
    change_column :tweet_metrics, :impression_count, :integer, null: true, default: nil
    change_column :tweet_metrics, :like_count, :integer, null: true, default: nil
    change_column :tweet_metrics, :retweet_count, :integer, null: true, default: nil
    change_column :tweet_metrics, :quote_count, :integer, null: true, default: nil
    change_column :tweet_metrics, :reply_count, :integer, null: true, default: nil
    change_column :tweet_metrics, :bookmark_count, :integer, null: true, default: nil
  end
end

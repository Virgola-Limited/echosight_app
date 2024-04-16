class AddMissingIndexesToTweetsAndTweetMetrics < ActiveRecord::Migration[7.1]
  def up
    add_index :tweet_metrics, :tweet_id, name: 'index_tweet_metrics_on_tweet_id' unless index_exists?(:tweet_metrics, :tweet_id)
    add_index :tweets, :identity_id, name: 'index_tweets_on_identity_id' unless index_exists?(:tweets, :identity_id)
    # Add other necessary indexes
  end

  def down
    remove_index :tweet_metrics, name: 'index_tweet_metrics_on_tweet_id' if index_exists?(:tweet_metrics, :tweet_id)
    remove_index :tweets, name: 'index_tweets_on_identity_id' if index_exists?(:tweets, :identity_id)
    # Remove other indexes if necessary
  end
end

class RestructureTweetMetricsAndTweets < ActiveRecord::Migration[7.1]
  def up
    # Assuming 'twitter_id' exists and is properly indexed in 'tweets'
    # Step 1: Drop existing foreign key constraints on 'tweet_metrics'
    remove_foreign_key :tweet_metrics, :tweets

    # Step 2: Change 'tweet_id' in 'tweet_metrics' to reference 'twitter_id' in 'tweets'
    # This involves changing the column type to match the 'twitter_id' and renaming it for clarity
    rename_column :tweet_metrics, :tweet_id, :old_tweet_id
    add_column :tweet_metrics, :new_tweet_id, :bigint

    # Populate new_tweet_id with twitter_id from tweets
    execute <<-SQL
      UPDATE tweet_metrics SET new_tweet_id = (SELECT twitter_id FROM tweets WHERE tweets.id = tweet_metrics.old_tweet_id);
    SQL

    # Remove old_tweet_id and rename new_tweet_id to tweet_id
    remove_column :tweet_metrics, :old_tweet_id
    rename_column :tweet_metrics, :new_tweet_id, :tweet_id

    # Step 3: Change primary key in 'tweets'
    execute "ALTER TABLE tweets DROP CONSTRAINT tweets_pkey CASCADE;"
    remove_column :tweets, :id
    rename_column :tweets, :twitter_id, :id
    execute "ALTER TABLE tweets ADD PRIMARY KEY (id);"

    # Step 4: Re-add foreign key constraint in 'tweet_metrics'
    add_foreign_key :tweet_metrics, :tweets, column: :tweet_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert this migration"
  end
end

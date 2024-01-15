class RemoveTweetCountsFromTweets < ActiveRecord::Migration[7.1]
  def change
    remove_column :tweets, :retweet_count
    remove_column :tweets, :quotes_count
    remove_column :tweets, :like_count
    remove_column :tweets, :quote_count
    remove_column :tweets, :impression_count
    remove_column :tweets, :reply_count
    remove_column :tweets, :bookmark_count
  end
end

class CreateTweetCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :tweet_counts do |t|
      t.integer :retweet_count
      t.integer :quotes_count
      t.integer :like_count
      t.integer :quote_count
      t.integer :impression_count
      t.integer :reply_count
      t.integer :bookmark_count
      t.datetime :pulled_at
      t.references :tweet, null: false, foreign_key: true

      t.timestamps
    end
  end
end

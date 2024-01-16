class CreateTweets < ActiveRecord::Migration[7.1]
  def change
    create_table :tweets do |t|
      t.bigint :twitter_id, null: false
      t.text :text, null: false
      t.integer :retweet_count
      t.integer :quotes_count
      t.integer :like_count
      t.integer :quote_count
      t.integer :impression_count
      t.integer :reply_count
      t.integer :bookmark_count
      t.references :identity, null: false, foreign_key: true
      t.timestamps
    end
    add_index :tweets, :twitter_id, unique: true
  end
end

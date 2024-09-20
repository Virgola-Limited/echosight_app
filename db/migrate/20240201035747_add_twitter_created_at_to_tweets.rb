class AddTwitterCreatedAtToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :twitter_created_at, :datetime
  end
end

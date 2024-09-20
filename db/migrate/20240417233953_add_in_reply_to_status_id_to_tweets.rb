class AddInReplyToStatusIdToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :in_reply_to_status_id, :bigint
    add_index :tweets, :in_reply_to_status_id # Optional: Add an index if you plan to query by this field
  end
end

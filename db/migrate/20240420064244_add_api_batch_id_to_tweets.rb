class AddApiBatchIdToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :api_batch_id, :bigint
    add_foreign_key :tweets, :api_batches, column: :api_batch_id
    add_index :tweets, :api_batch_id  # Adding an index for better query performance
  end
end

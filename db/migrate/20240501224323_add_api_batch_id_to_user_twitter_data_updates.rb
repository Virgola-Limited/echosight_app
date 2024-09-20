class AddApiBatchIdToUserTwitterDataUpdates < ActiveRecord::Migration[7.1]
  def change
    add_reference :user_twitter_data_updates, :api_batch, foreign_key: true
  end
end

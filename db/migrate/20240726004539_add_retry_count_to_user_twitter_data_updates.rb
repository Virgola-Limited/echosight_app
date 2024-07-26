class AddRetryCountToUserTwitterDataUpdates < ActiveRecord::Migration[7.1]
  def change
    add_column :user_twitter_data_updates, :retry_count, :integer, default: 0
  end
end

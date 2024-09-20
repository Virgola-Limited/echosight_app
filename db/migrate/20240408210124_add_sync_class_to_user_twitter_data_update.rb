class AddSyncClassToUserTwitterDataUpdate < ActiveRecord::Migration[7.1]
  def change
    add_column :user_twitter_data_updates, :sync_class, :string
  end
end

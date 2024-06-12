class AddSyncWithoutUserToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :sync_without_user, :boolean
  end
end

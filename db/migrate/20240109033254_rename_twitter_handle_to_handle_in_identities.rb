class RenameTwitterHandleToHandleInIdentities < ActiveRecord::Migration[7.0]
  def change
    rename_column :identities, :twitter_handle, :handle
    # rename_index :identities, 'index_identities_on_twitter_handle', 'index_identities_on_handle'
  end
end

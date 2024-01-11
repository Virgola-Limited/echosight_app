class RenameTwitterHandleToHandleInIdentities < ActiveRecord::Migration[7.0]
  def change
    rename_column :identities, :twitter_handle, :handle
  end
end

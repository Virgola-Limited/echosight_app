class AddTwitterHandleToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :twitter_handle, :string
    add_index :identities, :twitter_handle, unique: true
  end
end

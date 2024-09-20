class AddDescriptionToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :description, :string
  end
end

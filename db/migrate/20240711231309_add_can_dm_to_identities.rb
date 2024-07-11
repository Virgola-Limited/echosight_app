class AddCanDmToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :can_dm, :boolean
  end
end

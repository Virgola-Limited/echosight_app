class AddNameToUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :first_name, :last_name
    add_column :users, :name, :string
  end
end

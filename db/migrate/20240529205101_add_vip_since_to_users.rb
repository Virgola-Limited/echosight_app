class AddVipSinceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :vip_since, :date
  end
end

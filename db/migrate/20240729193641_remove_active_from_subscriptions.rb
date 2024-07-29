class RemoveActiveFromSubscriptions < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscriptions, :active, :boolean
  end
end

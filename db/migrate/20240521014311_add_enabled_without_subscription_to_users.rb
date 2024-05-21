class AddEnabledWithoutSubscriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :enabled_without_subscription, :boolean, default: false
  end
end

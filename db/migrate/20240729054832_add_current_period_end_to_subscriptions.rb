class AddCurrentPeriodEndToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :current_period_end, :datetime
  end
end

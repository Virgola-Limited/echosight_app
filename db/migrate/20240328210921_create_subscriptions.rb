class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id, index: true
      t.string :stripe_price_id, index: true
      t.boolean :active, default: true

      t.timestamps
    end
  end
end

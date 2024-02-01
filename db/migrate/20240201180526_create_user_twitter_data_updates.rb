class CreateUserTwitterDataUpdates < ActiveRecord::Migration[7.1]
  def change
    create_table :user_twitter_data_updates do |t|
      t.references :identity, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.text :error_message

      t.timestamps

      t.index :started_at
    end
  end
end

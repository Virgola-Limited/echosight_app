class CreateTwitterUpdateAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :twitter_update_attempts do |t|
      t.references :user_twitter_data_update, foreign_key: true
      t.string :status
      t.text :error_message
      t.timestamps
    end
  end
end

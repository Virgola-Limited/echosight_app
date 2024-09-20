class CreateTwitterFollowerCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :twitter_user_metrics do |t|
      t.string :followers_count
      t.references :identity, null: false, foreign_key: true
      t.date :date
      t.timestamps
    end
  end
end

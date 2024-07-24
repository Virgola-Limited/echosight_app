class CreateSentPosts < ActiveRecord::Migration[7.1]
    def change
      create_table :sent_posts do |t|
        t.text :message, null: false
        t.string :post_type, null: false
        t.boolean :sent, default: false
        t.datetime :sent_at
        t.jsonb :mentioned_users, default: []
        t.string :tracking_id, null: false
        t.integer :channel_type, null: false

        t.timestamps
      end

      add_index :sent_posts, :tracking_id, unique: true
    end
  end

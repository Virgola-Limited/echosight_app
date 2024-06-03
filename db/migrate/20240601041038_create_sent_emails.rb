class CreateSentEmails < ActiveRecord::Migration[6.0]
  def change
    create_table :sent_emails do |t|
      t.string :recipient, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.string :tracking_id, null: false
      t.string :email_type, null: false
      t.boolean :opened, default: false
      t.datetime :opened_at

      t.timestamps
    end
    add_index :sent_emails, :tracking_id, unique: true
  end
end
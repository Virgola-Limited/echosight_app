class AddUserIdToSentEmails < ActiveRecord::Migration[7.1]
  def change
    add_reference :sent_emails, :user, null: false, foreign_key: true
  end
end

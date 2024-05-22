class AddStatusToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :status, :string
  end
end

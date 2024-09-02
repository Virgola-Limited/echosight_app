class AddSearchIdToTweets < ActiveRecord::Migration[7.1]
  def change
    add_reference :tweets, :search, foreign_key: true, null: true
  end
end

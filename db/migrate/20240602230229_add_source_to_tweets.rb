class AddSourceToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :source, :string
  end
end

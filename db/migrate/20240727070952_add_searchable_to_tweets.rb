class AddSearchableToTweets < ActiveRecord::Migration[7.1]
  def change
    add_column :tweets, :searchable, :tsvector
    add_index :tweets, :searchable, using: :gin
  end
end

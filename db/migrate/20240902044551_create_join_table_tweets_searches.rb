class CreateJoinTableTweetsSearches < ActiveRecord::Migration[7.1]
  def change
    create_join_table :tweets, :searches do |t|
      t.index [:tweet_id, :search_id]
      t.index [:search_id, :tweet_id]
    end
  end
end

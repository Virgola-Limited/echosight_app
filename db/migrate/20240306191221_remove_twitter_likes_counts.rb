class RemoveTwitterLikesCounts < ActiveRecord::Migration[7.1]
  def change
    drop_table :twitter_likes_counts
  end
end

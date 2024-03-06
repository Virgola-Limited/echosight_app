class ChangeFollowersCountToInteger < ActiveRecord::Migration[7.1]
  def change
    change_column :twitter_user_metrics, :followers_count, :integer, using: 'followers_count::integer'
  end
end

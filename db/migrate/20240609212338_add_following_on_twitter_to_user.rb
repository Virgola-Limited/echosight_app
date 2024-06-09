class AddFollowingOnTwitterToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :following_on_twitter, :boolean, default: false
  end
end

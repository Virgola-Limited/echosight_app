class AddUserProfileClicksToTweetCount < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_counts, :user_profile_clicks, :integer
  end
end

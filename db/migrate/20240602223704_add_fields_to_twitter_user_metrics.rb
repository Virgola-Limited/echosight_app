class AddFieldsToTwitterUserMetrics < ActiveRecord::Migration[7.1]
  def change
    add_column :twitter_user_metrics, :following_count, :integer
    add_column :twitter_user_metrics, :listed_count, :integer
  end
end

class AddTitleToFeatureRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :feature_requests, :title, :string
  end
end

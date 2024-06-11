class CreateFeatureRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :feature_requests do |t|
      t.text :description
      t.timestamps
    end
  end
end

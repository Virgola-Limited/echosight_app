class CreateFeatureRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :feature_requests do |t|

      t.timestamps
    end
  end
end

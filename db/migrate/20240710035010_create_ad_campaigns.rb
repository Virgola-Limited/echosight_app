class CreateAdCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :ad_campaigns do |t|
      t.string :name
      t.string :campaign_id
      t.string :utm_source

      t.timestamps
    end
    add_index :ad_campaigns, :campaign_id, unique: true
  end
end

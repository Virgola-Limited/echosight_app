class RenameCampaignIdToAdCampaignIdInUsers < ActiveRecord::Migration[7.1]
  def change
    # Rename the column
    rename_column :users, :campaign_id, :ad_campaign_id

    # Change the column type
    change_column :users, :ad_campaign_id, 'bigint USING CAST(ad_campaign_id AS bigint)'

    # Add the foreign key constraint
    add_foreign_key :users, :ad_campaigns, column: :ad_campaign_id
  end
end

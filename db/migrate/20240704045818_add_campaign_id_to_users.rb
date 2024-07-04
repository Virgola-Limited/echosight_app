class AddCampaignIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :campaign_id, :string
  end
end

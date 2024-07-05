class AddAdCampaignToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :ad_campaign, :string
  end
end

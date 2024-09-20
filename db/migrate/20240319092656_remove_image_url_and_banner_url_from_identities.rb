class RemoveImageUrlAndBannerUrlFromIdentities < ActiveRecord::Migration[7.1]
  def change
    remove_column :identities, :image_url, :string
    remove_column :identities, :banner_url, :string
  end
end
class AddImageAndBannerToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :image_data, :text
    add_column :identities, :banner_data, :text
  end
end

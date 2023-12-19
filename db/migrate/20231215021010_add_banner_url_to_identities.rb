class AddBannerUrlToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :banner_url, :string
  end
end

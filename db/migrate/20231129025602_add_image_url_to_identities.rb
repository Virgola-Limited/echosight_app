class AddImageUrlToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :image_url, :string
  end
end

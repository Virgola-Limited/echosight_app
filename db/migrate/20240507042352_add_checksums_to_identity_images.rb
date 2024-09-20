  class AddChecksumsToIdentityImages < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :image_checksum, :string
    add_column :identities, :banner_checksum, :string
  end
end

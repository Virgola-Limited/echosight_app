class AddBearerTokenToIdentities < ActiveRecord::Migration[7.1]
  def change
    add_column :identities, :bearer_token, :string
  end
end

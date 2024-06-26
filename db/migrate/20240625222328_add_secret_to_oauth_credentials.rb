class AddSecretToOauthCredentials < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_credentials, :secret, :string
  end
end

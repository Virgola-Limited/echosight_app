class CreateOauthCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_credentials do |t|
      t.references :identity, null: false, foreign_key: true, index: { unique: true }
      t.string :provider
      t.string :token
      t.string :refresh_token
      t.datetime :expires_at
      t.timestamps
    end

    remove_column :identities, :bearer_token, :string
  end
end

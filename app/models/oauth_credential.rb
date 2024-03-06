# == Schema Information
#
# Table name: oauth_credentials
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  provider      :string
#  refresh_token :string
#  token         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identity_id   :bigint           not null
#
# Indexes
#
#  index_oauth_credentials_on_identity_id  (identity_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
class OauthCredential < ApplicationRecord
  belongs_to :identity

  def expired_or_expiring_soon?
    expires_at < Time.current + 5.minutes
  end
end

# == Schema Information
#
# Table name: oauth_credentials
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime
#  provider      :string
#  refresh_token :string
#  secret        :string
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

  # This model is a mismash of oauth2 and oauth1.
  # The token and secret are used for oauth1, and the token and refresh_token are used for oauth2.
  # if we decide we need both we should probably refactor
  # if we dont we should remove one of them

  def expired_or_expiring_soon?
    raise 'Wont work in Oauth2'
    expires_at < Time.current + 5.minutes
  end
end

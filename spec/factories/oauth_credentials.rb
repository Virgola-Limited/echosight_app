# frozen_string_literal: true

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
FactoryBot.define do
  factory :oauth_credential do
    association :identity
    provider { 'twitter2' }
    token { 'ekV3ZDhkQm9UbEV1ZDVLcWpjSlhLbk0yYXVFVjJ0WWphTTVKU1h2eW9ta245OjE3MDkxMDQyOTI3MjA6MToxOmF0OjE' }
    expires_at { Time.current + 1.hour }
  end
end

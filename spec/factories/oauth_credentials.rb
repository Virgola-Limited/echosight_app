FactoryBot.define do
  factory :oauth_credential do
    association :identity
    provider { "twitter2" }
    token { 'ekV3ZDhkQm9UbEV1ZDVLcWpjSlhLbk0yYXVFVjJ0WWphTTVKU1h2eW9ta245OjE3MDkxMDQyOTI3MjA6MToxOmF0OjE' }
    expires_at { Time.current + 1.hour }
  end
end
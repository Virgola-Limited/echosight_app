FactoryBot.define do
  factory :ad_campaign do
    name { "Sample Campaign" }
    campaign_id { "12345" }
    utm_source { "twitter" }
  end
end
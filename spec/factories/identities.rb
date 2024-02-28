FactoryBot.define do
  factory :identity do
    uid { '1691930809756991488' }
    association :user
    provider { 'twitter2' }
    handle { 'echosight' }
  end
end
# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    uid { '1691930809756991488' }
    association :user
    provider { 'twitter2' }
    handle { 'echosight' }

    trait :with_oauth_credential do
      after(:create) do |identity|
        create(:oauth_credential, identity:)
      end
    end

    trait :loftwah do
      uid { '1192091185' }
      association :user
      provider { 'twitter2' }
      handle { 'loftwah' }
    end
  end
end

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password' }
    confirmed_at { Time.now }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_identity do
      after(:create) do |user|
        create(:identity, user: user)
      end
    end

    trait :with_multiple_identities do
      after(:create) do |user|
        create(:identity, user: user, provider: 'twitter')
        create(:identity, user: user, provider: 'threads')
      end
    end

    trait :with_subscription do
      after(:create) do |user|
        create(:subscription, user: user)
      end
    end
  end
end

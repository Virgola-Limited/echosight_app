FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password' }
    confirmed_at { Time.now } # Set the confirmed_at attribute to the current time

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_identity do
      association :identity
    end

    trait :enabled_without_subscription do
      enabled_without_subscription { true }
    end

    trait :with_subscription do
      after(:create) do |user|
        create(:subscription, user:)
      end
    end
  end
end

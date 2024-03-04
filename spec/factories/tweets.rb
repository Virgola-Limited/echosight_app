# frozen_string_literal: true

FactoryBot.define do
  factory :tweet do
    twitter_id { Faker::Number.number(digits: 18) }
    text { Faker::Lorem.sentence }
  end
end

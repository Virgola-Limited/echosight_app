# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { 'blah@echosight.io' }
    password { 'password' }
    confirmed_at { Time.now } # Set the confirmed_at attribute to the current time
  end
end

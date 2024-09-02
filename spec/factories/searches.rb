FactoryBot.define do
  factory :search do
    keywords { Faker::Lorem.words(number: 3).join(' ') }
    platform { 'twitter' }
    user
  end
end
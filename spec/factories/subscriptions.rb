# == Schema Information
#
# Table name: subscriptions
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  stripe_price_id        :string
#  stripe_subscription_id :string
#  user_id                :bigint           not null
#
# Indexes
#
#  index_subscriptions_on_stripe_price_id         (stripe_price_id)
#  index_subscriptions_on_stripe_subscription_id  (stripe_subscription_id)
#  index_subscriptions_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :subscription do
    stripe_subscription_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    stripe_price_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    status { 'active' }
    association :user

    trait :inactive do
      status { 'canceled' }
    end

    trait :trialing do
      status { 'trialing' }
    end
  end
end

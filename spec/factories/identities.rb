# frozen_string_literal: true

# == Schema Information
#
# Table name: identities
#
#  id                :bigint           not null, primary key
#  banner_checksum   :string
#  banner_data       :text
#  description       :string
#  handle            :string
#  image_checksum    :string
#  image_data        :text
#  provider          :string
#  sync_without_user :boolean
#  uid               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint
#
# Indexes
#
#  index_identities_on_handle   (handle) UNIQUE
#  index_identities_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :identity do
    uid { Faker::Alphanumeric.alpha(number: 19) }
    association :user
    provider { 'twitter' }
    handle { Faker::Internet.unique.username }
    description { 'Twitter user bio' }

    trait :random_credentials do
      uid { SecureRandom.uuid }
      handle { Faker::Internet.unique.username }
    end

    trait :with_oauth_credential do
      after(:create) do |identity|
        create(:oauth_credential, identity:)
      end
    end

    trait :tophertoy do
      uid { '1691930809756991488' }
      handle { 'TopherToy' }
    end

    trait :loftwah do
      uid { '1192091185' }
      association :user
      provider { 'twitter' }
      handle { 'loftwah' }
    end

    trait :syncable_without_user do
      sync_without_user { true }
      user { nil }
    end

    trait :syncable_without_subscription do
      user { create(:user, :enabled_without_subscription) }
    end
  end
end

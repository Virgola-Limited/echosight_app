# frozen_string_literal: true

# == Schema Information
#
# Table name: tweets
#
#  id                 :bigint           not null, primary key
#  text               :text             not null
#  twitter_created_at :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  identity_id        :bigint           not null
#
# Indexes
#
#  index_tweets_on_id           (id) UNIQUE
#  index_tweets_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
FactoryBot.define do
  factory :tweet do
    twitter_id { Faker::Number.number(digits: 18) }
    text { Faker::Lorem.sentence }
    association :identity
  end
end

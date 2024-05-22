# frozen_string_literal: true

# == Schema Information
#
# Table name: tweets
#
#  id                    :bigint           not null, primary key
#  status                :string
#  text                  :text             not null
#  twitter_created_at    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  api_batch_id          :bigint
#  identity_id           :bigint           not null
#  in_reply_to_status_id :bigint
#
# Indexes
#
#  index_tweets_on_api_batch_id           (api_batch_id)
#  index_tweets_on_id                     (id) UNIQUE
#  index_tweets_on_identity_id            (identity_id)
#  index_tweets_on_in_reply_to_status_id  (in_reply_to_status_id)
#
# Foreign Keys
#
#  fk_rails_...  (api_batch_id => api_batches.id)
#  fk_rails_...  (identity_id => identities.id)
#
FactoryBot.define do
  factory :tweet do
    id { Faker::Number.number(digits: 18) }
    text { Faker::Lorem.sentence }
    association :identity
    association :api_batch
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: tweet_metrics
#
#  id                  :bigint           not null, primary key
#  bookmark_count      :integer          default(0), not null
#  impression_count    :integer          default(0), not null
#  like_count          :integer          default(0), not null
#  pulled_at           :datetime
#  quote_count         :integer          default(0), not null
#  reply_count         :integer          default(0), not null
#  retweet_count       :integer          default(0), not null
#  updated_count       :integer          default(0), not null
#  user_profile_clicks :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tweet_id            :bigint
#
# Indexes
#
#  index_tweet_metrics_on_tweet_id  (tweet_id)
#
# Foreign Keys
#
#  fk_rails_...  (tweet_id => tweets.id)
#
FactoryBot.define do
  factory :tweet_metric do
    tweet
    retweet_count { 10 }
    like_count { 20 }
    quote_count { 5 }
    impression_count { 100 }
    reply_count { 2 }
    bookmark_count { 3 }
    pulled_at { DateTime.current }

    trait :zero_metrics do
      retweet_count { 0 }
      like_count { 0 }
      quote_count { 0 }
      impression_count { 0 }
      reply_count { 0 }
      bookmark_count { 0 }
    end
  end
end

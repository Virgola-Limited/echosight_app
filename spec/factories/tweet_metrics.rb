# == Schema Information
#
# Table name: tweet_metrics
#
#  id                  :bigint           not null, primary key
#  bookmark_count      :integer
#  impression_count    :integer
#  like_count          :integer
#  pulled_at           :date
#  quote_count         :integer
#  reply_count         :integer
#  retweet_count       :integer
#  user_profile_clicks :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tweet_id            :bigint           not null
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
    pulled_at { Time.current }
  end
end

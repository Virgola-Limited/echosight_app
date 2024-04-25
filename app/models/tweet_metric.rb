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
class TweetMetric < ApplicationRecord
  has_paper_trail

  validates :impression_count, numericality: { greater_than_or_equal_to: 0 }
  validates :like_count, numericality: { greater_than_or_equal_to: 0 }
  validates :retweet_count, numericality: { greater_than_or_equal_to: 0 }
  validates :quote_count, numericality: { greater_than_or_equal_to: 0 }
  validates :reply_count, numericality: { greater_than_or_equal_to: 0 }
  validates :bookmark_count, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :tweet

  def self.ransackable_associations(auth_object = nil)
    ["tweet"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["bookmark_count", "created_at", "id", "id_value", "impression_count", "like_count", "pulled_at", "quote_count", "reply_count", "retweet_count", "tweet_id", "updated_at", "user_profile_clicks", "updated_count"]
  end


  def engagement_rate_percentage
    interactions = retweet_count.to_f +
    quote_count.to_f +
    like_count.to_f +
    reply_count.to_f +
    bookmark_count.to_f
    impressions = impression_count.to_f

    return 0.0 if impressions.zero?

    ((interactions / impressions) * 100).round(2)
  end

end

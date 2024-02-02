# frozen_string_literal: true

class TweetMetric < ApplicationRecord
  belongs_to :tweet

  def self.ransackable_associations(auth_object = nil)
    ["tweet"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["bookmark_count", "created_at", "id", "id_value", "impression_count", "like_count", "pulled_at", "quote_count", "reply_count", "retweet_count", "tweet_id", "updated_at", "user_profile_clicks"]
  end

end

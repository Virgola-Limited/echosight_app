# frozen_string_literal: true

class Tweet < ApplicationRecord
  belongs_to :identity
  has_many :tweet_metrics, dependent: :destroy

  validates :twitter_id, presence: true, uniqueness: true
  validates :identity_id, presence: true
  validates :text, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "identity_id", "text", "twitter_created_at", "twitter_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["identity", "tweet_metrics"]
  end
end

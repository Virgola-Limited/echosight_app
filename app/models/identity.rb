# frozen_string_literal: true
class Identity < ApplicationRecord
  belongs_to :user
  has_many :hourly_tweet_counts, dependent: :destroy
  has_many :tweets, dependent: :destroy
  has_many :twitter_followers_counts, dependent: :destroy
  has_many :twitter_likes_counts, dependent: :destroy
  has_many :user_twitter_data_updates, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :handle, uniqueness: true, presence: true

  scope :valid_identity, -> {
    where(provider: "twitter2")
  }

  def self.ransackable_attributes(auth_object = nil)
    ["banner_url", "bearer_token", "created_at", "description", "handle", "id", "id_value", "image_url", "provider", "uid", "updated_at", "user_id"]
  end
end

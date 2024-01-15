# frozen_string_literal: true
class Identity < ApplicationRecord
  belongs_to :user
  has_many :tweet_hourly_counts, dependent: :destroy
  has_many :tweets, dependent: :destroy
  has_many :twitter_followers_counts, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :handle, uniqueness: true, presence: true

  scope :valid_identity, -> {
    where(provider: "twitter2")
  }
end

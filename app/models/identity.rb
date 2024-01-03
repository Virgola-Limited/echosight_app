# app/models/identity.rb
class Identity < ApplicationRecord
  belongs_to :user
  has_many :tweet_hourly_counts, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  # should probably be just called handle (should be social network agnostic)
  validates :twitter_handle, uniqueness: true, presence: true
end

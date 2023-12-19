# app/models/identity.rb
class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  # should probably be just called handle (should be social network agnostic)
  validates :twitter_handle, uniqueness: true, presence: true
end

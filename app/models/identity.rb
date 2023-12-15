# app/models/identity.rb
class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :twitter_handle, uniqueness: true, presence: true
end

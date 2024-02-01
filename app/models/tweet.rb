# frozen_string_literal: true

class Tweet < ApplicationRecord
  belongs_to :identity
  has_many :tweet_metrics, dependent: :destroy

  validates :twitter_id, presence: true, uniqueness: true
  validates :identity_id, presence: true
  validates :text, presence: true
end

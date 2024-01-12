# frozen_string_literal: true

class Tweet < ApplicationRecord
  belongs_to :identity

  validates :twitter_id, presence: true, uniqueness: true
  validates :identity_id, presence: true
  validates :text, presence: true
end

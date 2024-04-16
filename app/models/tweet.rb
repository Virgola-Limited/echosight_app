# frozen_string_literal: true

# == Schema Information
#
# Table name: tweets
#
#  id                 :bigint           not null, primary key
#  text               :text             not null
#  twitter_created_at :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  identity_id        :bigint           not null
#
# Indexes
#
#  index_tweets_on_id           (id) UNIQUE
#  index_tweets_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
class Tweet < ApplicationRecord
  attr_accessor :engagement_rate_percentage

  belongs_to :identity
  has_one :user, through: :identity
  has_many :tweet_metrics, dependent: :destroy

  validates :identity_id, presence: true
  validates :text, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "identity_id", "text", "twitter_created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["identity", "tweet_metrics"]
  end

  # Alias twitter_id to id
  def twitter_id
    self.id
  end

  def twitter_id=(value)
    self.id = value
  end

end

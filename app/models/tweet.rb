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
#  twitter_id         :bigint           not null
#
# Indexes
#
#  index_tweets_on_identity_id  (identity_id)
#  index_tweets_on_twitter_id   (twitter_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
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

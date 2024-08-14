# frozen_string_literal: true

# == Schema Information
#
# Table name: tweets
#
#  id                    :bigint           not null, primary key
#  searchable            :tsvector
#  source                :string
#  status                :string
#  text                  :text             not null
#  twitter_created_at    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  api_batch_id          :bigint
#  identity_id           :bigint           not null
#  in_reply_to_status_id :bigint
#
# Indexes
#
#  index_tweets_on_api_batch_id           (api_batch_id)
#  index_tweets_on_id                     (id) UNIQUE
#  index_tweets_on_identity_id            (identity_id)
#  index_tweets_on_in_reply_to_status_id  (in_reply_to_status_id)
#  index_tweets_on_searchable             (searchable) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (api_batch_id => api_batches.id)
#  fk_rails_...  (identity_id => identities.id)
#
class Tweet < ApplicationRecord
  before_save :update_searchable

  attr_accessor :engagement_rate

  belongs_to :api_batch
  belongs_to :identity
  has_one :user, through: :identity
  has_many :tweet_metrics, dependent: :destroy

  validates :identity_id, presence: true
  validates :text, presence: true

  scope :empty_status, -> { where(status: nil) }

  def self.max_age_for_refresh
    2.days.ago - 1.hour
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "identity_id", "text", "twitter_created_at", "updated_at", "updated_count"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["identity", "tweet_metrics"]
  end

  def update_searchable
    self.searchable = Tweet.connection.execute(
      Tweet.sanitize_sql(["SELECT to_tsvector('english', ?)", text])
    ).values.flatten.first
  end

end


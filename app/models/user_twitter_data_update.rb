# frozen_string_literal: true

# == Schema Information
#
# Table name: user_twitter_data_updates
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  error_message :text
#  started_at    :datetime         not null
#  sync_class    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  api_batch_id  :bigint
#  identity_id   :bigint           not null
#
# Indexes
#
#  index_user_twitter_data_updates_on_api_batch_id  (api_batch_id)
#  index_user_twitter_data_updates_on_identity_id   (identity_id)
#  index_user_twitter_data_updates_on_started_at    (started_at)
#
# Foreign Keys
#
#  fk_rails_...  (api_batch_id => api_batches.id)
#  fk_rails_...  (identity_id => identities.id)
#
class UserTwitterDataUpdate < ApplicationRecord
  belongs_to :identity
  has_one :api_batch

  scope :recent_data, ->(identity_id) { where(identity_id: identity_id).where('created_at > ?', 7.days.ago).where.not(completed_at: nil) }


  def self.ransackable_associations(auth_object = nil)
    ["identity"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["completed_at", "created_at", "error_message", "id", "id_value", "identity_id", "started_at", "updated_at"]
  end
end

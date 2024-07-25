# == Schema Information
#
# Table name: sent_posts
#
#  id              :bigint           not null, primary key
#  channel_type    :integer          not null
#  mentioned_users :jsonb
#  message         :text             not null
#  post_type       :string           not null
#  sent            :boolean          default(FALSE)
#  sent_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tracking_id     :string           not null
#
# Indexes
#
#  index_sent_posts_on_tracking_id  (tracking_id) UNIQUE
#
class SentPost < ApplicationRecord
  enum channel_type: { slack: 0, twitter: 1, threads: 2 }

  validates :message, :tracking_id, :post_type, :channel_type, presence: true

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["message", "created_at", "post_type", "id", "sent", "sent_at", "mentioned_users", "tracking_id", "updated_at"]
  end
end

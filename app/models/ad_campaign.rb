# == Schema Information
#
# Table name: ad_campaigns
#
#  id          :bigint           not null, primary key
#  name        :string
#  utm_source  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :string
#
# Indexes
#
#  index_ad_campaigns_on_campaign_id  (campaign_id) UNIQUE
#
class AdCampaign < ApplicationRecord
  before_create :generate_unique_campaign_id

  has_many :users

  validates :name, presence: true
  validates :utm_source, presence: true, inclusion: { in: %w[twitter threads instagram] }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "name", "utm_source"]
  end

  private

  def generate_unique_campaign_id
    self.campaign_id = SecureRandom.uuid
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: identities
#
#  id              :bigint           not null, primary key
#  banner_checksum :string
#  banner_data     :text
#  description     :string
#  handle          :string
#  image_checksum  :string
#  image_data      :text
#  provider        :string
#  uid             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_identities_on_handle   (handle) UNIQUE
#  index_identities_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Identity < ApplicationRecord
  include ImageUploader::Attachment(:image) # adds an 'image' virtual attribute
  include ImageUploader::Attachment(:banner) # adds a 'banner' virtual attribute

  belongs_to :user
  has_many :tweets, dependent: :destroy
  has_many :twitter_user_metrics, dependent: :destroy
  has_many :user_twitter_data_updates, dependent: :destroy
  has_one :oauth_credential, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :handle, uniqueness: true, presence: true

  scope :valid_identity, -> {
    where(provider: "twitter2")
  }
  scope :sorted_by_followers_count, -> {
    joins('LEFT OUTER JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
    .select('identities.*, COALESCE(MAX(twitter_user_metrics.followers_count), 0) AS max_followers_count')
    .group('identities.id')
    .order('max_followers_count DESC')
  }

  def self.find_by_handle(handle)
    Identity.where('lower(handle) = ?', handle.downcase)&.first
  end

  def self.ransackable_attributes(auth_object = nil)
    ["banner_url", "created_at", "description", "handle", "id", "id_value", "image_url", "provider", "uid", "updated_at", "user_id"]
  end

  def assign_attributes_from_auth(auth)
    self.provider = auth.provider
    self.uid = auth.uid
    self.description = auth.info.description
    self.handle = auth.extra.raw_info.data.username
  end

  def enough_data_for_public_page?
    user_twitter_data_updates.recent_data(self.id).count > 40
  end

  def page_low_on_recent_data?
    !enough_data_for_public_page?
  end

  def valid_identity?
    provider == "twitter2"
  end
end

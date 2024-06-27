# == Schema Information
#
# Table name: identities
#
#  id                :bigint           not null, primary key
#  banner_checksum   :string
#  banner_data       :text
#  description       :string
#  handle            :string
#  image_checksum    :string
#  image_data        :text
#  provider          :string
#  sync_without_user :boolean
#  uid               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint
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

  belongs_to :user, optional: true # Allow identity creation without a user
  has_many :tweets, dependent: :destroy
  has_many :twitter_user_metrics, dependent: :destroy
  has_many :user_twitter_data_updates, dependent: :destroy
  has_one :oauth_credential, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :handle, uniqueness: true, presence: true

  scope :valid_identity, lambda {
    where(provider: 'twitter')
  }
  scope :sorted_by_followers_count, lambda {
    joins('LEFT OUTER JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
      .select('identities.*, COALESCE(MAX(twitter_user_metrics.followers_count), 0) AS max_followers_count')
      .group('identities.id')
      .order('max_followers_count DESC')
  }
  scope :syncable, lambda {
    left_outer_joins(:user)
      .where('identities.sync_without_user = ? OR (identities.user_id IS NOT NULL AND (users.enabled_without_subscription = ? OR EXISTS (
        SELECT 1
        FROM subscriptions
        WHERE subscriptions.user_id = identities.user_id
        AND subscriptions.active = ?
      )))', true, true, true)
      .where('users.confirmed_at IS NOT NULL OR identities.user_id IS NULL')
  }

  def self.find_by_handle(handle)
    Identity.where('lower(handle) = ?', handle.downcase)&.first
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[banner_url created_at description handle id id_value image_url provider uid
       updated_at user_id]
  end

  def assign_attributes_from_auth(auth)
    self.provider = auth.provider
    self.uid = auth.uid
    self.description = auth.info.description
    # oauth 1
    self.handle = auth.info.nickname
    # oauth 2
    # self.handle = auth.extra.raw_info.data.username
  end

  def enough_data_for_public_page?
    user_twitter_data_updates.recent_data(id).count > 40
  end

  def page_low_on_recent_data?
    !enough_data_for_public_page?
  end

  def unclaimed?
    user.nil?
  end

  def valid_identity?
    # this broke when we changed from twitter2 to twitter
    # perhaps we dont need this method
    true
  end

  def syncable?
    !!(sync_without_user || (user&.confirmed? && valid_identity? && (user.active_subscription? || user.enabled_without_subscription?)))
  end
end

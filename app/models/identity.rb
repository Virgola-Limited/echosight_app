# == Schema Information
#
# Table name: identities
#
#  id                :bigint           not null, primary key
#  banner_checksum   :string
#  banner_data       :text
#  can_dm            :boolean
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
#  index_identities_on_handle            (handle) UNIQUE
#  index_identities_on_uid_and_provider  (uid,provider) UNIQUE
#  index_identities_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Identity < ApplicationRecord
  include ImageUploader::Attachment(:image) # adds an 'image' virtual attribute
  include ImageUploader::Attachment(:banner) # adds a 'banner' virtual attribute

  has_paper_trail
  before_update :disable_versioning_if_uid_updated

  belongs_to :user, optional: true # Allow identity creation without a user
  has_many :tweets
  has_many :twitter_user_metrics
  has_many :user_twitter_data_updates, dependent: :destroy
  has_one :oauth_credential, dependent: :destroy

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :handle, uniqueness: true, presence: true

  attribute :provider, :string, default: 'twitter'

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
    active_subscription_ids = Subscription.active.select(:id)

    left_outer_joins(user: :subscriptions)
      .where('identities.sync_without_user = ? OR (identities.user_id IS NOT NULL AND (users.enabled_without_subscription = ? OR EXISTS (
        SELECT 1
        FROM subscriptions
        WHERE subscriptions.user_id = identities.user_id
        AND subscriptions.id IN (?)
      )))', true, true, active_subscription_ids)
      .where('users.confirmed_at IS NOT NULL OR identities.user_id IS NULL')
  }

  scope :without_user, lambda {
    left_outer_joins(:user)
      .where(users: { id: nil })
  }

  def self.find_by_handle(handle)
    Identity.where('lower(handle) = ?', handle.downcase)&.first
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[banner_url created_at description handle id id_value image_url provider uid
       updated_at user_id, sync_without_user]
  end

  def self.ransackable_associations(auth_object = nil)
    ['user']
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

  def destroy_image_and_banner!
    # Destroy the image
    if image_attacher.present?
      image_attacher.destroy
      self.image = nil
      self.image_data = nil
      self.image_checksum = nil
    end

    # Destroy the banner
    if banner_attacher.present?
      banner_attacher.destroy
      self.banner = nil
      self.banner_data = nil
      self.banner_checksum = nil
    end

    save!
  end

  def enough_data_for_public_page?
    user_twitter_data_updates.count > 7
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

  def uid_updated_before?
    versions.any? do |version|
      version.reify&.uid != uid
    end
  end

  private

  def disable_versioning_if_uid_updated
    if uid_changed? && uid_updated_before?
      PaperTrail.request.disable_model(self.class)
    end
  end
end

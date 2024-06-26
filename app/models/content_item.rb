# == Schema Information
#
# Table name: content_items
#
#  id         :bigint           not null, primary key
#  category   :string
#  content    :text             not null
#  image_data :text
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_content_items_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ContentItem < ApplicationRecord
  include ImageUploader::Attachment(:image)  # associates an image with this model

  belongs_to :user

  # Validations
  validates :content, presence: true, length: { maximum: 280 }  # Ensures content is not empty and does not exceed 280 characters
  validates :user, presence: true
  validate :validate_image_type_and_size, if: -> { image.present? }

  # hack to schedule for our user id remove the 81 later
  after_create :schedule_tweet, if: -> { category == 'app_update' && user_id == 1 }

  def self.ransackable_attributes(auth_object = nil)
    super - ['image_data']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def schedule_tweet
    Twitter::PostTweetJob.perform_in(5.days, id)
  end

  def validate_image_type_and_size
    if image.mime_type !~ /\Aimage\/(jpeg|png|gif)\z/
      errors.add(:image, 'must be a JPEG, PNG, or GIF')
    end

    if image.size > 5.megabytes
      errors.add(:image, 'size should be less than 5MB')
    end
  end
end


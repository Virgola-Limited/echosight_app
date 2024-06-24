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
  validates :content, presence: true  # Ensures that content is not empty
  validates :user, presence: true

  def self.ransackable_attributes(auth_object = nil)
    super - ['image_data']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

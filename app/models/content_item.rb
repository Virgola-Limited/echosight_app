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
#
class ContentItem < ApplicationRecord
  include ImageUploader::Attachment(:image)  # associates an image with this model

  # Validations
  validates :content, presence: true  # Ensures that content is not empty

  def self.ransackable_attributes(auth_object = nil)
    super - ['image_data']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

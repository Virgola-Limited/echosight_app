# == Schema Information
#
# Table name: feature_requests
#
#  id          :bigint           not null, primary key
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class FeatureRequest < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  has_many :votes, as: :votable
end

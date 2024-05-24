# == Schema Information
#
# Table name: feature_requests
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class FeatureRequest < ApplicationRecord
  validates :description, presence: true
  has_many :votes, as: :votable
end

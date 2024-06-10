# == Schema Information
#
# Table name: feature_requests
#
#  id          :bigint           not null, primary key
#  description :text
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_feature_requests_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class FeatureRequest < ApplicationRecord
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  has_many :votes, as: :votable
end

# == Schema Information
#
# Table name: bug_reports
#
#  id          :bigint           not null, primary key
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class BugReport < ApplicationRecord
  validates :description, presence: true
  has_many :votes, as: :votable
end

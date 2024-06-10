# == Schema Information
#
# Table name: bug_reports
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
#  index_bug_reports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class BugReport < ApplicationRecord
  validates :title, presence: true, uniqueness: { case_sensitive: false }
  has_many :votes, as: :votable
end

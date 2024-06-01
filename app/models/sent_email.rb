# == Schema Information
#
# Table name: sent_emails
#
#  id          :bigint           not null, primary key
#  body        :text             not null
#  email_type  :string           not null
#  opened      :boolean          default(FALSE)
#  opened_at   :datetime
#  recipient   :string           not null
#  subject     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tracking_id :string           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_sent_emails_on_tracking_id  (tracking_id) UNIQUE
#  index_sent_emails_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class SentEmail < ApplicationRecord
  belongs_to :user
  validates :recipient, :subject, :body, :tracking_id, :email_type, presence: true
end


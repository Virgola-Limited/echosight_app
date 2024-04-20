# == Schema Information
#
# Table name: api_batches
#
#  id           :bigint           not null, primary key
#  completed_at :datetime
#  status       :string           default("pending")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ApiBatch < ApplicationRecord
  has_many :tweets
  has_many :user_twitter_data_updates

  def complete_batch
    update(completed_at: Time.current, status: 'completed')
  end

  def fail_batch
    update(status: 'failed')
  end
end

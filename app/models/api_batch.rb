class ApiBatch < ApplicationRecord
  has_many :user_twitter_data_updates

  def complete_batch
    update(completed_at: Time.current, status: 'completed')
  end

  def fail_batch
    update(status: 'failed')
  end
end
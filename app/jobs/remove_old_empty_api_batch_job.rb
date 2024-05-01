

class RemoveOldEmptyApiBatchJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform
    # if ApiBatch has status completed and is over 24 hours old and has no tweets then delete
    ApiBatch.where(status: 'completed').where('completed_at < ?', 24.hours.ago).where('id NOT IN (?)', Tweet.select(:api_batch_id)).destroy_all
  end
end
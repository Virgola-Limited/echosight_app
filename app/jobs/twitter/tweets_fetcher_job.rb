module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      api_batch = ApiBatch.create!(status: 'processing')
      User.syncable.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id, api_batch.id)
        # What do we do if the code above fails?
        Twitter::ExistingTweetsUpdater.perform_in(23.5.hours, user.id, api_batch_id)
      end
      # Not sure if this is the best approach.
      api_batch.update!(status: 'completed', completed_at: Time.current)



    end
  end
end

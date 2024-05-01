module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      api_batch = ApiBatch.create!(status: 'processing')
      User.syncable.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id, api_batch.id)
      end
      # Not sure if this is the best approach.
      api_batch.update!(status: 'completed', completed_at: Time.current)

      Twitter::TweetDataCheckJob.perform_in(30.minutes)
    end
  end
end

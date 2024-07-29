module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      return if ENV['DISABLE_TWEETS_FETCHER_JOB']
      api_batch = ApiBatch.create!(status: 'processing')
      Identity.syncable.find_each do |identity|
        Twitter::NewTweetsFetcherJob.perform_async(identity.id, api_batch.id)
      end
      # Not sure if this is the best approach.
      api_batch.update!(status: 'completed', completed_at: Time.current)

      Twitter::TweetDataCheckJob.perform_in(30.minutes)
    end
  end
end

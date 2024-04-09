module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      User.syncable.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id)
        Twitter::ExistingTweetsUpdaterJob.perform_async(user.id)
      end
    end
  end
end
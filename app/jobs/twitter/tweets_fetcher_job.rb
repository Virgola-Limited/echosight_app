module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(client_class_name: nil)
      User.syncable.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id)
      end
      Twitter::ExistingTweetsUpdaterJob.perform_async
    end
  end
end
module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      User.syncable.find_each do |user|
        Twitter::UserTweetsHandlerJob.perform_async(user.id)
      end
    end
  end

  # Keep this private for now only run through TweetsFetcherJob
  class UserTweetsHandlerJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(user_id)
      Twitter::NewTweetsFetcherJob.new.perform(user_id)
      Twitter::ExistingTweetsUpdaterJob.new.perform(user_id)
    end
  end
end

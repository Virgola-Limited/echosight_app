module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(client_class_name: nil)
      User.syncable.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id, client_class_name, within_time: '1h')
      end
    end

  end
end
module Twitter
  class TweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(client_class_name: nil)
    # TODO: - dont enqueue this if its been done in the last 24 hours for a user so we can stagger the user
      confirmed_users.find_each do |user|
        Twitter::NewTweetsFetcherJob.perform_async(user.id, client_class_name, within_time: '1h')
      end
    end

    private

    def confirmed_users
      User.confirmed.joins(:identity).merge(Identity.valid_identity)
    end
  end
end
module Twitter
  class NewTweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(user_id, client_class_name = nil)
      user = User.find(user_id)
      client_class = client_class_name.constantize if client_class_name
      fetch_and_log_twitter_data(user, client_class)
    end

    private

    def fetch_and_log_twitter_data(user, client_class = nil)
      data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current)

      begin
        update_user(user, client_class)
      rescue StandardError => e
        message = "NewTweetsFetcherJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message}"
        data_update_log.update!(error_message: message)
        raise message
      else
        data_update_log.update!(completed_at: Time.current)
      end
    end

    def update_user(user, client_class = nil)
      client = client_class.new(user) if client_class
      Twitter::NewTweetsFetcher.new(user:, client:).call
    end
  end
end
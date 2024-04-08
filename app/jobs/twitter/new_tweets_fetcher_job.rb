module Twitter
  class NewTweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform
      User.syncable.each do |user|
        fetch_and_log_twitter_data(user)
      end
    end

    private

    def fetch_and_log_twitter_data(user)
      data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current, sync_class: Twitter::NewTweetsFetcher)

      begin
        update_user(user)
      rescue StandardError => e
        message = "NewTweetsFetcherJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message}"
        data_update_log.update!(error_message: message)
        raise message
      else
        data_update_log.update!(completed_at: Time.current)
      end
    end

    def update_user(user)
      Twitter::NewTweetsFetcher.new(user:, within_time: '1h').call
    end
  end
end
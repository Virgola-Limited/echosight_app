module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(user_id)
      user = User.find(user_id)
      p "**user_id: #{user_id}"
      fetch_and_log_twitter_data(user)
    end

    private

    def fetch_and_log_twitter_data(user)
      data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current, sync_class: Twitter::ExistingTweetsUpdater)

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
      Twitter::ExistingTweetsUpdater.new(user: user).call
    end
  end
end
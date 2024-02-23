
module Twitter
  class DataUpdateJobBase
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(user_id: nil)
      if user_id
        user = User.find(user_id)
        fetch_and_log_twitter_data(user)
        return
      end

      confirmed_users.each do |user|
        fetch_and_log_twitter_data(user)
      end
    end

    private

    def fetch_and_log_twitter_data(user)
      data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current)

      begin
        update_user(user)
      rescue StandardError => e
        message = "Failed to complete update for user #{user.id} #{user.email}: #{e.message}"
        data_update_log.update(error_message: message)
        raise message
      else
        data_update_log.update(completed_at: Time.current) # Set completed_at only if no errors occurred.
      end
    end

    def update_user(user)
      raise NotImplementedError, 'This method should be implemented by subclasses'
    end

    def confirmed_users
      User.confirmed.joins(:identity).merge(Identity.valid_identity)
    end
  end
end

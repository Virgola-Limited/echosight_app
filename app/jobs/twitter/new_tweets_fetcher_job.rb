module Twitter
  class NewTweetsFetcherJob < Services::Base
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(user_id, api_batch_id)
      user = User.find(user_id)
      api_batch = ApiBatch.find(api_batch_id)
      fetch_and_log_twitter_data(user, api_batch)
    end

    private

    def fetch_and_log_twitter_data(user, api_batch)
      data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current, sync_class: Twitter::NewTweetsFetcher)

      begin
        update_user(user, api_batch)
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")  # Join the full backtrace into a single string
        # Optionally, you could select just the first few lines to avoid overly verbose output:
        # backtrace = e.backtrace.take(5).join("\n")

        message = "NewTweetsFetcherJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
        data_update_log.update!(error_message: message)
        raise e
      else
        data_update_log.update!(completed_at: Time.current)
      end
    end

    def update_user(user, api_batch)
      Twitter::NewTweetsFetcher.new(user: user, api_batch_id: api_batch.id).call
    end
  end
end

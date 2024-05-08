module Twitter
  class NewTweetsFetcherJob < Services::Base
    include Sidekiq::Job
    # Need to decide how to handle retries for this job
    # since it could fail in here or the child jobs
    sidekiq_options retry: false

    def perform(user_id, api_batch_id)
      user = User.find(user_id)
      api_batch = ApiBatch.find(api_batch_id)

      begin
        fetch_and_log_twitter_data(user, api_batch)
      ensure
        # This ensure block runs whether the fetch_and_log_twitter_data succeeds or fails
        schedule_updater_if_needed(user, api_batch)
      end
    end

    private

    def fetch_and_log_twitter_data(user, api_batch)
      user_twitter_data_update = UserTwitterDataUpdate.create!(
        identity_id: user.identity.id,
        started_at: Time.current,
        sync_class: Twitter::NewTweetsFetcher
      )

      begin
        update_user(user, api_batch)
      rescue StandardError => e
        handle_error(user, api_batch, e, user_twitter_data_update)
      else
        user_twitter_data_update.update!(completed_at: Time.current)
      end
    end

    def update_user(user, api_batch)
      Twitter::NewTweetsFetcher.new(user: user, api_batch_id: api_batch.id).call
    end

    def handle_error(user, api_batch, e, user_twitter_data_update)
      backtrace = e.backtrace.join("\n")
      message = "NewTweetsFetcherJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
      user_twitter_data_update.update!(error_message: message)
      raise e
    end

    def schedule_updater_if_needed(user, api_batch)
      # Ensure we only schedule the job if there are tweets for this user in the batch
      if api_batch.tweets.exists?(identity_id: user.identity.id)
        Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, user.id, api_batch.id)
      end
    end
  end
end

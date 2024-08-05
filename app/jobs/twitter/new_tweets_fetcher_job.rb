# frozen_string_literal: true

module Twitter
  class NewTweetsFetcherJob
    include Sidekiq::Job
    sidekiq_options queue: :tweet_syncing,
      lock: :until_and_while_executing,
      unique_across_queues: true,
      lock_timeout: 1.hour,
      on_conflict: { client: :log, server: :reschedule },
      unique_args: :unique_args

    def self.unique_args(_args)
      []
    end


    def perform(identity_id, api_batch_id)

      identity = Identity.find(identity_id)
      api_batch = ApiBatch.find(api_batch_id)
      message = "Temporary logging: Starting Twitter::NewTweetsFetcherJob for api_batch: #{api_batch.id} and identity: #{identity.id}"
      Notifications::SlackNotifier.call(message: message, channel: :general)
      return unless identity.syncable?

      @user_twitter_data_update = UserTwitterDataUpdate.find_or_initialize_by(identity_id: identity.id, api_batch_id: api_batch.id, completed_at: nil)
      @user_twitter_data_update.update!(started_at: Time.current, retry_count: @user_twitter_data_update.retry_count + 1, sync_class: self.class.name)

      begin
        fetch_and_log_twitter_data(identity, api_batch)
      rescue StandardError => e
        handle_error(identity, api_batch, e)
      else
        log_attempt("success", nil)
        @user_twitter_data_update.update!(completed_at: Time.current, error_message: nil)
        schedule_updater_if_needed(identity, api_batch)
      end
    end

    private

    def fetch_and_log_twitter_data(identity, api_batch)
      update_user(identity, api_batch)
    end

    def update_user(identity, api_batch)
      Twitter::NewTweetsFetcher.new(identity: identity, api_batch_id: api_batch.id).call
    end

    def handle_error(identity, api_batch, e)
      log_attempt("failed", error_message(e, identity, api_batch))
      @user_twitter_data_update.update!(error_message: error_message(e, identity, api_batch))
      raise e
    end

    def error_message(e, identity, api_batch)
      backtrace = e.backtrace.join("\n")
      "NewTweetsFetcherJob: Failed to complete update for identity #{identity.id}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
    end

    def log_attempt(status, error_message)
      @user_twitter_data_update.twitter_update_attempts.create!(
        status: status,
        error_message: error_message,
        created_at: Time.current
      )
    end

    def schedule_updater_if_needed(identity, api_batch)
      if api_batch.tweets.exists?(identity_id: identity.id)
        Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, identity.id, api_batch.id)
      end
    end
  end
end

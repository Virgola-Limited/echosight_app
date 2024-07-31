# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdaterJob
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

    attr_reader :api_batch, :identity, :user_twitter_data_update

    def perform(identity_id, api_batch_id)
      @identity = Identity.find(identity_id)
      @api_batch = ApiBatch.find(api_batch_id)
      return unless identity.syncable?

      @user_twitter_data_update = UserTwitterDataUpdate.find_or_initialize_by(identity_id: identity.id, api_batch_id: api_batch.id, completed_at: nil)
      @user_twitter_data_update.update!(started_at: Time.current, retry_count: @user_twitter_data_update.retry_count + 1)

      fetch_and_log_twitter_data
    end

    private

    def fetch_and_log_twitter_data
      begin
        update_user
      rescue StandardError => e
        log_attempt("failed", error_message(e))
        user_twitter_data_update.update!(error_message: error_message(e))
        raise e
      else
        log_attempt("success", nil)
        user_twitter_data_update.update!(completed_at: Time.current, error_message: nil)
        schedule_updater_if_needed
      end
    end

    def update_user
      Twitter::ExistingTweetsUpdater.new(identity: identity, api_batch_id: api_batch.id).call
    end

    def user_tweets_updatable?
      api_batch.created_at > Tweet.max_age_for_refresh && identity.syncable?
    end

    def schedule_updater_if_needed
      if user_tweets_updatable?
        Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, identity.id, api_batch.id)
      end
    end

    def error_message(e)
      backtrace = e.backtrace.join("\n")
      user = identity&.user
      credentials = user ? "user #{user.id} #{user.email}" : "identity #{identity.id} #{identity.handle}"
      "ExistingTweetsUpdaterJob: Failed to complete update for #{credentials}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
    end

    def log_attempt(status, error_message)
      user_twitter_data_update.twitter_update_attempts.create!(
        status: status,
        error_message: error_message,
        created_at: Time.current
      )
    end
  end
end

# frozen_string_literal: true

require 'sidekiq-unique-jobs'

module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job
    sidekiq_options unique: :until_executed, unique_args: ->(args) { args }

    attr_reader :api_batch, :identity

    def perform(identity_id, api_batch_id)
      @identity = Identity.find(identity_id)
      @api_batch = ApiBatch.find(api_batch_id)
      fetch_and_log_twitter_data
    end

    private

    def fetch_and_log_twitter_data
      if identity.syncable?
        user_twitter_data_update = UserTwitterDataUpdate.create!(
          identity_id: identity.id,
          started_at: Time.current,
          sync_class: Twitter::ExistingTweetsUpdater,
          api_batch_id: api_batch.id
        )

        begin
          update_user
        rescue StandardError => e
          user_twitter_data_update.update!(error_message: error_message(e))
          raise e
        else
          user_twitter_data_update.update!(completed_at: Time.current)
        end
        # byebug
        if user_tweets_updatable?
          Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, identity.id, api_batch.id)
        end
      end
    end

    def update_user
      Twitter::ExistingTweetsUpdater.new(identity: identity, api_batch_id: api_batch.id).call
    end

    def user_tweets_updatable?
      api_batch.created_at > Tweet.max_age_for_refresh && identity.syncable?
    end

    def error_message(e)
      # byebug
      backtrace = e.backtrace.join("\n")  # Join the full backtrace into a single string
      # Optionally, you could select just the first few lines to avoid overly verbose output:
      # backtrace = e.backtrace.take(5).join("\n")

      user = identity&.user
      if user
        credentials = "user #{user.id} #{user.email}"
      else
        credentials = "identity #{identity.id} #{identity.handle}"
      end

      "ExistingTweetsUpdaterJob: Failed to complete update for #{credentials}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
    end
  end
end

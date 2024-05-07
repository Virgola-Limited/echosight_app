# frozen_string_literal: true

require 'sidekiq-unique-jobs'

module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job
    sidekiq_options retry: false
    sidekiq_options unique: :until_executed, unique_args: ->(args) { args }

    attr_reader :api_batch, :user

    def perform(user_id, api_batch_id)
      @user = User.find(user_id)
      @api_batch = ApiBatch.find(api_batch_id)
      fetch_and_log_twitter_data
    end

    private

    def fetch_and_log_twitter_data
      if user.syncable?
        user_twitter_data_update = UserTwitterDataUpdate.create!(
          identity_id: user.identity.id,
          started_at: Time.current,
          sync_class: Twitter::ExistingTweetsUpdater,
          api_batch_id: api_batch.id
        )

        begin
          update_user
        rescue StandardError => e
          backtrace = e.backtrace.join("\n")  # Join the full backtrace into a single string
          # Optionally, you could select just the first few lines to avoid overly verbose output:
          # backtrace = e.backtrace.take(5).join("\n")

          message = "ExistingTweetsUpdaterJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message} ApiBatch: #{api_batch.id}\nBacktrace:\n#{backtrace}"
          user_twitter_data_update.update!(error_message: message)
          raise e
        else
          user_twitter_data_update.update!(completed_at: Time.current)
        end

        if user_tweets_updatable?
          Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, user.id, api_batch.id)
        end
      end
    end

    def update_user
      Twitter::ExistingTweetsUpdater.new(user: user, api_batch_id: api_batch.id).call
    end

    def user_tweets_updatable?
      api_batch.created_at > Tweet.max_age_for_refresh && user.syncable?
    end
  end
end

# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job
    sidekiq_options retry: false

    attr_reader :api_batch_id, :user

    def perform(user_id, api_batch_id)
      @user = User.find(user_id)
      @api_batch_id = api_batch_id
      fetch_and_log_twitter_data
    end

    private

    def fetch_and_log_twitter_data
      data_update_log = UserTwitterDataUpdate.create!(
        identity_id: user.identity.id,
        started_at: Time.current,
        sync_class: Twitter::ExistingTweetsUpdater
      )

      begin
        update_user
      rescue StandardError => e
        message = "ExistingTweetsUpdaterJob: Failed to complete update for user #{user.id} #{user.email}: #{e.message}"
        data_update_log.update!(error_message: message)
        raise message
      else
        data_update_log.update!(completed_at: Time.current)
      end
      schedule_next_update
    end

    def update_user
      Twitter::ExistingTweetsUpdater.new(user: user, api_batch_id: api_batch_id).call
    end

    def schedule_next_update
      api_batch = ApiBatch.find(api_batch_id)
      # Only schedule the next update if the ApiBatch is less than 15 days old
      if api_batch.created_at > 15.days.ago
        Twitter::ExistingTweetsUpdaterJob.perform_in(24.hours, user.id, api_batch_id)
      end
    end
  end
end

# frozen_string_literal: true

module Twitter
  class UserMetricsUpdater
    def initialize(user_data)
      @user_data = user_data
    end

    def call
      update_followers_count
    end

    private

    def update_followers_count
      return unless @user_data.is_a?(Hash)

      identity = Identity.find_by(handle: @user_data['username'])
      return unless identity

      TwitterUserMetric.find_or_initialize_by(
        identity_id: identity.id,
        date: Date.current
      ).update!(
        followers_count: @user_data.dig('public_metrics', 'followers_count')
        # TODO update other metrics
      )
    end
  end
end

# frozen_string_literal: true

module Twitter
  class UserMetricsUpdater
    attr_reader :user_data

    def initialize(user_data)
      @user_data = user_data
    end

    def call
      metrics_updated = update_followers_count
      send_slack_notification(metrics_updated)
      if metrics_updated
        return "Twitter user metrics updated for #{@user_data['username']}."
      end
      "No updates were made to Twitter user metrics for #{@user_data['username']}."
    end

    private

    def update_followers_count
      raise "#{self.class.name}: Invalid user data: #{@user_data}" unless @user_data.is_a?(Hash)

      identity = Identity.find_by!(handle: user_data['username'])

      twitter_user_metric = TwitterUserMetric.find_or_initialize_by(
        identity_id: identity.id,
        date: Date.current
      )

      twitter_user_metric.followers_count = @user_data.dig('public_metrics', 'followers_count')
      metrics_updated = twitter_user_metric.changed?
      twitter_user_metric.save! if metrics_updated

      metrics_updated
    end

    def send_slack_notification(metrics_updated)
      message = if metrics_updated
                  "Twitter user metrics updated for #{@user_data['username']}."
                else
                  "No updates were made to Twitter user metrics for #{@user_data['username']}."
                end

      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end

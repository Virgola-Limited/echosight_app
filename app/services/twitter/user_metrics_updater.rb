# frozen_string_literal: true

module Twitter
  class UserMetricsUpdater
    attr_reader :user_data

    def initialize(user_data)
      @user_data = user_data
    end

    def call
      update_followers_count
    end

    private

    def update_followers_count
      raise "#{self.class.name}: Invalid user data: #{@user_data}" unless @user_data.is_a?(Hash)

      identity = Identity.find_by_uid(user_data['id'])
      raise "Identity not found for user: #{@user_data['username']} #{@user_data['uid']}" unless identity

      twitter_user_metric = TwitterUserMetric.find_or_initialize_by(
        identity_id: identity.id,
        date: Date.current
      )
      fields_to_update.each do |field|
        twitter_user_metric.send("#{field}=", @user_data.dig('public_metrics', field))
      end
      metrics_updated = twitter_user_metric.changed?
      twitter_user_metric.save!
    end

    def fields_to_update
      %w[followers_count following_count listed_count]
    end
  end
end

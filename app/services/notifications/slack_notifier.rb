module Notifications
  class SlackNotifier
    def self.call(message:, channel: :general)
      return if ENV['DISABLE_SLACK_NOTIFY']

      webhook_urls = Rails.application.credentials.slack[:webhook_url]
      webhook_url = webhook_urls[Rails.env.to_sym] || webhook_urls[channel] || webhook_urls[:general]

      notifier = Slack::Notifier.new(webhook_url)
      notifier.ping("#{Rails.env.upcase}: #{message}")
    end
  end
end
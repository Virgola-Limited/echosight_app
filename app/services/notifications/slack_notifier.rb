module Notifications
  class SlackNotifier
    def initialize(channel: nil)
      channel = channel || '#default'
      @notifier = Slack::Notifier.new(Rails.application.credentials.slack[:webhook_url], channel: channel)
    end

    def self.call(message:, channel: nil)
      self.new(channel: nil).ping(message)
    end
  end
end
module Notifications
  class SlackNotifier
    def self.call(message:, channel: nil)
      channel = channel || '#default'
      notifier = Slack::Notifier.new(Rails.application.credentials.slack[:webhook_url], channel: channel)
      notifier.ping(message)
    end
  end
end

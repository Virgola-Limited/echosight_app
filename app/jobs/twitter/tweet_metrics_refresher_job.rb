# frozen_string_literal: true

module Twitter
  class TweetMetricsRefresherJob < Twitter::DataUpdateJobBase
    private

    def update_user(user, client_class = nil)
      client = client_class.new(user) if client_class
      updater_class.new(user:, client:).call
    end

    def updater_class
      Twitter::TweetMetricsRefresher
    end
  end
end

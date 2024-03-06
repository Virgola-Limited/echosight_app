# frozen_string_literal: true

module Twitter
  class TweetsFetcherJob < Twitter::DataUpdateJobBase
    private

    # TODO: - dont enqueue this if its been done in the last 24 hours for a user
    # so we can stagger the user
    def update_user(user, client_class = nil)
      client = client_class.new(user) if client_class
      updater_class.new(user:, client:).call
    end

    def updater_class
      Twitter::TweetsFetcher
    end
  end
end

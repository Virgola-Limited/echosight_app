# frozen_string_literal: true

module Twitter
  class NewTweetsFetcherJob < Twitter::DataUpdateJobBase
    private

    def update_user(user)
      Twitter::NewTweetsFetcher.new(user:).call
    end
  end
end

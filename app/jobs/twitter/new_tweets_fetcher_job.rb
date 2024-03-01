module Twitter
  class NewTweetsFetcherJob < Twitter::DataUpdateJobBase
    private

    def update_user(user)
      Twitter::NewTweetsFetcher.new(user: user).call
    end
  end
end
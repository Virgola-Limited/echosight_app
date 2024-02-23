module Twitter
  class TweetMetricsRefresherJob < Twitter::DataUpdateJobBase
    private

    def update_user(user)
      Twitter::TweetMetricsRefresher.new(user).call
    end
  end
end
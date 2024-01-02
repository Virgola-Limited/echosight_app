module Twitter
  class TweetCountsQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def this_weeks_tweets_count
      fetch_tweet_counts_from_last_week
    end

    private

    def fetch_tweet_counts_from_last_week
      endpoint = 'tweets/counts/recent'
      params = {
        'query' => "from:#{user.twitter_handle}",
        'start_time' => 1.week.ago.utc.iso8601
      }

      response = x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
      response.is_a?(Hash) && response.key?('meta') ? response['meta']['total_tweet_count'] : 0
    end

    def x_client
      @x_client ||= TwitterClientService.new.client
    end
  end
end

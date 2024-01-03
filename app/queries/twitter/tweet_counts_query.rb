module Twitter
  class TweetCountsQuery
    attr_reader :user

    def initialize(user, start_time = nil)
      @user = user
      @start_time = start_time || 1.week.ago.utc.iso8601
    end

    def this_weeks_tweets_count
      endpoint = 'tweets/counts/recent'
      params = {
        'query' => "from:#{user.twitter_handle}",
        'start_time' =>  @start_time,
      }

      x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def x_client
      @x_client ||= TwitterClientService.new.client
    end
  end
end

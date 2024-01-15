module Twitter
  class ImpressionsQuery
    attr_reader :user, :tweet_id

    def initialize(user, tweet_id)
      @user = user
    end

    def fetch_impressions
      if tweet_id
        tweet = user.identity.tweets.find_by(twitter_id: tweet_id)
        tweet ? tweet.impression_count : 0
      else
        user.identity.tweets.sum(:impression_count)
      end
    end
  end
end

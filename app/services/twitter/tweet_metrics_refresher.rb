module Twitter
  class TweetMetricsRefresher
    attr_reader :user, :twitter_client

    BATCH_SIZE = 100
    MAX_TWEETS_TO_UPDATE = 1400

    def initialize(user)
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      # Process tweets less than 30 days old
      outdated_tweet_ids.each_slice(BATCH_SIZE) do |batch|
        update_tweets_and_metrics(batch, include_non_public_metrics: true)
      end

      # Process tweets older than 30 days
      # Dean says we dont need this and we are hitting limits on the basic plan
      # outdated_tweet_ids(recent: false).each_slice(BATCH_SIZE) do |batch|
      #   update_tweets_and_metrics(batch, include_non_public_metrics: false)
      # end
    end

    private

    def outdated_tweet_ids#(recent: true)
      scope = user.identity.tweets.order(updated_at: :asc)
      # if recent
        scope.where('twitter_created_at > ?', 30.days.ago).pluck(:twitter_id)
      # else
        # scope.where('twitter_created_at <= ?', 30.days.ago).pluck(:twitter_id)
      # end
    end

    def update_tweets_and_metrics(tweet_ids, include_non_public_metrics: true)
      tweets_data = twitter_client.fetch_tweets_by_ids(tweet_ids, include_non_public_metrics)

      tweets_data['data'].each do |tweet_data|
        process_tweet_data(tweet_data, include_non_public_metrics)
      end
    end

    def process_tweet_data(tweet_data, include_non_public_metrics)
      tweet = Tweet.find_or_initialize_by(twitter_id: tweet_data['id'])
      metrics = tweet_data['public_metrics']
      tweet.touch

      metric_attributes = {
        tweet: tweet,
        retweet_count: metrics['retweet_count'],
        quote_count: metrics['quote_count'],
        like_count: metrics['like_count'],
        impression_count: metrics['impression_count'],
        reply_count: metrics['reply_count'],
        bookmark_count: metrics['bookmark_count'],
        pulled_at: DateTime.now.utc
      }

      if include_non_public_metrics
        non_public_metrics = tweet_data['non_public_metrics']
        metric_attributes.merge!(
          user_profile_clicks: non_public_metrics.fetch('user_profile_clicks', nil)  # Optional
        )
      end

      TweetMetric.create!(metric_attributes)
    end
  end
end

#  Twitter::TweetMetricsRefresher.new(user).call
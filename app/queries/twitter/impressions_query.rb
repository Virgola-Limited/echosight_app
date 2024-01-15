module Twitter
  class ImpressionsQuery
    attr_reader :user, :tweet_id

    def initialize(user, tweet_id: nil)
      @user = user
      # @tweet_id = tweet_id
    end

    def impressions_count
      if tweet_id
        sum_last_tweet_counts_per_day_for_tweet(tweet_id)
      else
        sum_last_tweet_counts_per_day_for_all_user_tweets
      end
    end

    def top_tweets_for_user
      tweets_table = Tweet.arel_table
      tweet_counts_table = TweetCount.arel_table

      # Define SQL for total engagement
      total_engagement_sql = <<-SQL
        COALESCE(MAX(tweet_counts.retweet_count), 0) +
        COALESCE(MAX(tweet_counts.quotes_count), 0) +
        COALESCE(MAX(tweet_counts.like_count), 0) +
        COALESCE(MAX(tweet_counts.quote_count), 0) +
        COALESCE(MAX(tweet_counts.impression_count), 0) +
        COALESCE(MAX(tweet_counts.reply_count), 0) +
        COALESCE(MAX(tweet_counts.bookmark_count), 0) AS total_engagement
      SQL

      # Define SQL for individual max count metrics
      metrics_sql = <<-SQL
        MAX(tweet_counts.retweet_count) AS retweet_count,
        MAX(tweet_counts.quotes_count) AS quotes_count,
        MAX(tweet_counts.like_count) AS like_count,
        MAX(tweet_counts.quote_count) AS quote_count,
        MAX(tweet_counts.impression_count) AS impression_count,
        MAX(tweet_counts.reply_count) AS reply_count
      SQL

      Tweet.joins(:tweet_counts)
           .where(tweets_table[:identity_id].eq(user.identity.id))
           .select("tweets.*, #{total_engagement_sql}, #{metrics_sql}")
           .group(tweets_table[:id])
           .order(Arel.sql('total_engagement DESC'))
           .limit(5)
    end


    private

    def sum_last_tweet_counts_per_day_for_tweet(tweet_id)
      TweetCount.where(tweet_id: tweet_id)
                .group("DATE(pulled_at)")
                .order("DATE(pulled_at), pulled_at DESC")
                .pluck("DISTINCT ON (DATE(pulled_at)) impression_count")
                .sum
    end

    def sum_last_tweet_counts_per_day_for_all_user_tweets
      TweetCount.joins(:tweet)
                .where(tweets: { identity_id: user.identity.id })
                .select('DISTINCT ON (tweet_counts.tweet_id, DATE(tweet_counts.pulled_at)) tweet_counts.*')
                .order('tweet_counts.tweet_id', Arel.sql('DATE(tweet_counts.pulled_at)'), 'tweet_counts.pulled_at DESC')
                .group_by { |tc| [tc.tweet_id, tc.pulled_at.to_date] }
                .map { |_, tweet_counts| tweet_counts.max_by(&:pulled_at).impression_count }
                .sum
    end

  end
end
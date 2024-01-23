
# consider renameingy when we decide
# on what data to use.
module Twitter
  class EngagementQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Fetches the sum of the most recent retweet counts for all tweets of the user
    def total_retweets
      # Define a subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the retweet_count from these latest TweetMetric records
      total_retweets = TweetMetric
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.retweet_count')

      total_retweets
    end

    # Fetches the sum of the most recent reply counts for all tweets of the user
    def total_replies
      # Reuse the subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the reply_count from these latest TweetMetric records
      total_replies = TweetMetric
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.reply_count')

      total_replies
    end

    def total_likes
      # Reuse the subquery to get the latest TweetMetric record for each tweet
      latest_tweet_counts_subquery = TweetMetric
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_metrics.tweet_id) tweet_metrics.*')
                                      .order('tweet_metrics.tweet_id, tweet_metrics.pulled_at DESC')
                                      .to_sql

      # Sum the like_count from these latest TweetMetric records
      total_likes = TweetMetric
                      .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                      .sum('latest_tweet_counts.like_count')

      total_likes
    end
  end
end

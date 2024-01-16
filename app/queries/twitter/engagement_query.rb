
# consider renameing to TweetCountsQuery when we dedide
# on what data to use.
module Twitter
  class EngagementQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Fetches the sum of the most recent retweet counts for all tweets of the user
    def total_retweets
      # Define a subquery to get the latest TweetCount record for each tweet
      latest_tweet_counts_subquery = TweetCount
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_counts.tweet_id) tweet_counts.*')
                                      .order('tweet_counts.tweet_id, tweet_counts.pulled_at DESC')
                                      .to_sql

      # Sum the retweet_count from these latest TweetCount records
      total_retweets = TweetCount
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.retweet_count')

      total_retweets
    end

    # Fetches the sum of the most recent reply counts for all tweets of the user
    def total_replies
      # Reuse the subquery to get the latest TweetCount record for each tweet
      latest_tweet_counts_subquery = TweetCount
                                      .joins(tweet: { identity: :user })
                                      .where(users: { id: user.id })
                                      .select('DISTINCT ON (tweet_counts.tweet_id) tweet_counts.*')
                                      .order('tweet_counts.tweet_id, tweet_counts.pulled_at DESC')
                                      .to_sql

      # Sum the reply_count from these latest TweetCount records
      total_replies = TweetCount
                        .from("(#{latest_tweet_counts_subquery}) as latest_tweet_counts")
                        .sum('latest_tweet_counts.reply_count')

      total_replies
    end
  end
end

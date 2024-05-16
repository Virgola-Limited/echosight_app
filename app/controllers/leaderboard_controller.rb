# app/controllers/leaderboard_controller.rb
class LeaderboardController < ApplicationController
  def tweets
    @tweets = Tweet.joins(:tweet_metrics)
                   .select('tweets.*, tweet_metrics.impression_count, tweet_metrics.retweet_count, tweet_metrics.like_count, tweet_metrics.quote_count, tweet_metrics.reply_count, tweet_metrics.bookmark_count')
                   .order('tweet_metrics.impression_count DESC')
                   .limit(50)
  end

  def users
    @users = Identity.joins(tweets: :tweet_metrics)
                     .select('identities.*, SUM(tweet_metrics.impression_count) AS total_impressions, SUM(tweet_metrics.retweet_count) AS total_retweets, SUM(tweet_metrics.like_count) AS total_likes, SUM(tweet_metrics.quote_count) AS total_quotes, SUM(tweet_metrics.reply_count) AS total_replies, SUM(tweet_metrics.bookmark_count) AS total_bookmarks')
                     .group('identities.id')
                     .order('total_impressions DESC')
                     .limit(50)
  end
end

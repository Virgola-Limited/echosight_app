# app/controllers/leaderboard_controller.rb
class LeaderboardController < ApplicationController
  def tweets
    @tweets = Tweet.joins(:tweet_metrics)
                   .select('tweets.*, tweet_metrics.impression_count, tweet_metrics.retweet_count, tweet_metrics.like_count, tweet_metrics.quote_count, tweet_metrics.reply_count, tweet_metrics.bookmark_count')
                   .order('tweet_metrics.impression_count DESC')
                   .limit(50)
  end

  def users
    start_date = case params[:period]
                 when 'today'
                   Time.current.beginning_of_day
                 when '7_days'
                   7.days.ago
                 when '28_days'
                   28.days.ago
                 when '3_months'
                   3.months.ago
                 when '1_year'
                   1.year.ago
                 end

    # Check if there are any tweets from today
    if params[:period] == 'today'
      tweets_today = Tweet.where('created_at >= ?', Time.current.beginning_of_day)
      if tweets_today.empty?
        start_date = 1.day.ago.beginning_of_day
      end
    end

    @users = Identity.joins(tweets: :tweet_metrics)
                     .joins('LEFT JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
                     .select('identities.*,
                                SUM(tweet_metrics.impression_count) AS total_impressions,
                                SUM(tweet_metrics.retweet_count) AS total_retweets,
                                SUM(tweet_metrics.like_count) AS total_likes,
                                SUM(tweet_metrics.quote_count) AS total_quotes,
                                SUM(tweet_metrics.reply_count) AS total_replies,
                                SUM(tweet_metrics.bookmark_count) AS total_bookmarks,
                                MAX(twitter_user_metrics.followers_count) AS total_followers,
                                (SUM(tweet_metrics.retweet_count) + SUM(tweet_metrics.like_count) + SUM(tweet_metrics.quote_count) + SUM(tweet_metrics.reply_count) + SUM(tweet_metrics.bookmark_count)) / NULLIF(SUM(tweet_metrics.impression_count), 0) * 100 AS engagement_rate,
                                MIN(tweet_metrics.created_at) AS date_first_collected')
                     .group('identities.id')
                     .order('total_impressions DESC')
                     .limit(50)

    @users = @users.where('tweet_metrics.created_at >= ?', start_date) if start_date
  end
end

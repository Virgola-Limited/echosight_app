class LeaderboardController < ApplicationController
  def tweets
    date_range = params[:date_range] || '7_days'
    start_date = Twitter::LeaderboardQuery.start_date_for_period(date_range)

    @tweets = Tweet.joins(:tweet_metrics, :identity)
                   .where('tweet_metrics.created_at >= ?', start_date)
                   .select('tweets.*, identities.handle, identities.image_data, tweet_metrics.impression_count, tweet_metrics.retweet_count, tweet_metrics.like_count, tweet_metrics.quote_count, tweet_metrics.reply_count, tweet_metrics.bookmark_count')
                   .order('tweet_metrics.impression_count DESC')
                   .limit(25)
  end

  def users
    date_range = params[:date_range] || '7_days'
    @users = Twitter::LeaderboardQuery.new(date_range: date_range).identity_leaderboard
    render :users
  end
end

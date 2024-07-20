class LeaderboardController < ApplicationController
  PERIODS = {
    'today' => -> { Time.current.beginning_of_day },
    '7_days' => -> { 7.days.ago },
    '28_days' => -> { 28.days.ago },
    '3_months' => -> { 3.months.ago },
    '1_year' => -> { 1.year.ago }
  }.freeze

  def tweets
    date_range = params[:date_range] || '7_days'
    start_date = start_date_for_period(date_range)

    @tweets = Tweet.joins(:tweet_metrics, :identity)
                   .where('tweet_metrics.created_at >= ?', start_date)
                   .select('tweets.*, identities.handle, identities.image_data, tweet_metrics.impression_count, tweet_metrics.retweet_count, tweet_metrics.like_count, tweet_metrics.quote_count, tweet_metrics.reply_count, tweet_metrics.bookmark_count')
                   .order('tweet_metrics.impression_count DESC')
                   .limit(25)
  end

  def users
    date_range = params[:date_range] || '7_days'
    @users = Twitter::LeaderboardQuery.new(date_range: date_range).call
    render :users
  end

  def start_date_for_period(date_range)
    start_date = PERIODS.fetch(date_range, PERIODS['7_days']).call

    if date_range == 'today'
      tweets_today = Tweet.where('created_at >= ?', Time.current.beginning_of_day)
      start_date = 1.day.ago.beginning_of_day if tweets_today.empty?
    end

    start_date
  end
end

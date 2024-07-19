class LeaderboardController < ApplicationController
  PERIODS = {
    'today' => -> { Time.current.beginning_of_day },
    '7_days' => -> { 7.days.ago },
    '28_days' => -> { 28.days.ago },
    '3_months' => -> { 3.months.ago },
    '1_year' => -> { 1.year.ago }
  }.freeze

  before_action :set_flash_message

  def tweets
    period = params[:period] || '7_days'
    start_date = start_date_for_period(period)

    @tweets = Tweet.joins(:tweet_metrics, :identity)
                   .where('tweet_metrics.created_at >= ?', start_date)
                   .select('tweets.*, identities.handle, identities.image_data, tweet_metrics.impression_count, tweet_metrics.retweet_count, tweet_metrics.like_count, tweet_metrics.quote_count, tweet_metrics.reply_count, tweet_metrics.bookmark_count')
                   .order('tweet_metrics.impression_count DESC')
                   .limit(50)
  end

  def users
    period = params[:period] || '7_days'
    start_date = start_date_for_period(period)

    subquery = Tweet.joins(:tweet_metrics)
                    .where('tweet_metrics.created_at >= ?', start_date)
                    .group('tweets.identity_id')
                    .select('tweets.identity_id,
                             COALESCE(SUM(tweet_metrics.impression_count), 0) AS total_impressions,
                             COALESCE(SUM(tweet_metrics.retweet_count), 0) AS total_retweets,
                             COALESCE(SUM(tweet_metrics.like_count), 0) AS total_likes,
                             COALESCE(SUM(tweet_metrics.quote_count), 0) AS total_quotes,
                             COALESCE(SUM(tweet_metrics.reply_count), 0) AS total_replies,
                             COALESCE(SUM(tweet_metrics.bookmark_count), 0) AS total_bookmarks')

    @users = Identity.joins("LEFT JOIN (#{subquery.to_sql}) AS tweet_data ON tweet_data.identity_id = identities.id")
                     .joins('LEFT JOIN twitter_user_metrics ON twitter_user_metrics.identity_id = identities.id')
                     .select('identities.id,
                              identities.handle,
                              identities.image_data,
                              tweet_data.total_impressions,
                              tweet_data.total_retweets,
                              tweet_data.total_likes,
                              tweet_data.total_quotes,
                              tweet_data.total_replies,
                              tweet_data.total_bookmarks,
                              MAX(twitter_user_metrics.followers_count) AS total_followers,
                              (COALESCE(tweet_data.total_retweets, 0) + COALESCE(tweet_data.total_likes, 0) + COALESCE(tweet_data.total_quotes, 0) + COALESCE(tweet_data.total_replies, 0) + COALESCE(tweet_data.total_bookmarks, 0)) / NULLIF(COALESCE(tweet_data.total_impressions, 0), 0) * 100 AS engagement_rate')
                     .where('tweet_data.total_impressions > 0')
                     .group('identities.id, identities.handle, tweet_data.total_impressions, tweet_data.total_retweets, tweet_data.total_likes, tweet_data.total_quotes, tweet_data.total_replies, tweet_data.total_bookmarks')
                     .order('tweet_data.total_impressions DESC')
                     .limit(50)

    render :users
  end

  private

  def set_flash_message
    if current_or_guest_user.guest?
      link = view_context.link_to('Sign up', new_user_registration_path).html_safe
      flash.now[:notice] = " #{link} to get your own Echosight public page.".html_safe
    end
  end

  def start_date_for_period(period)
    start_date = PERIODS.fetch(period, PERIODS['7_days']).call

    if period == 'today'
      tweets_today = Tweet.where('created_at >= ?', Time.current.beginning_of_day)
      start_date = 1.day.ago.beginning_of_day if tweets_today.empty?
    end

    Rails.logger.info "Start date: #{start_date}"
    start_date
  end
end

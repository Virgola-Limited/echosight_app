# frozen_string_literal: true

module Twitter
  class LeaderboardQuery
    PERIODS = {
      'today' => -> { Time.current.beginning_of_day },
      '7_days' => -> { 7.days.ago },
      '28_days' => -> { 28.days.ago },
      '3_months' => -> { 3.months.ago },
      '1_year' => -> { 1.year.ago }
    }.freeze

    attr_reader :date_range, :start_date

    def initialize(date_range: '7_days')
      @date_range = date_range
      @start_date = start_date_for_period(date_range)
    end

    def call
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

      Identity.joins("LEFT JOIN (#{subquery.to_sql}) AS tweet_data ON tweet_data.identity_id = identities.id")
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
              .limit(25)
    end

    private

    def start_date_for_period(date_range)
      start_date = PERIODS.fetch(date_range, PERIODS['7_days']).call

      if date_range == 'today'
        tweets_today = Tweet.where('created_at >= ?', Time.current.beginning_of_day)
        start_date = 1.day.ago.beginning_of_day if tweets_today.empty?
      end

      start_date
    end
  end
end

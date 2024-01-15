# frozen_string_literal: true

class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(handle: params[:handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user

    @tweets_count = tweet_count_query.this_weeks_tweets_count

    @tweets_change_since_last_week = tweet_count_query.tweets_change_since_last_week
    if @tweets_change_since_last_week.is_a?(Integer)
      @tweets_change_since_last_week = @tweets_change_since_last_week.to_s
    else
      @days_until_last_weeks_data_available = tweet_count_query.days_until_last_weeks_data_available
      "Collecting data. Check back later in #{@days_until_last_weeks_data_available} days."
    end

    # @impressions_count = Twitter::ImpressionsQuery.new(@user, params[:tweet_id]).fetch_impressions
    followers_query = Twitter::FollowersQuery.new(@user)
    @followers_count = followers_query.followers_count
    @followers_count_change_percentage_text = followers_query.followers_count_change_percentage

    formatted_data, daily_data_points = followers_query.followers_data_for_graph
    formatted_data, daily_data_points = followers_query.followers_data_for_graph
    Rails.logger.debug("paul Controller - Formatted Labels: #{@formatted_labels_for_graph}")
    Rails.logger.debug("paul Controller - Daily Data Points: #{@daily_data_points_for_graph}")
    @formatted_labels_for_graph = formatted_data
    @daily_data_points_for_graph = daily_data_points
    Rails.logger.debug('paul @daily_data_points_for_graph' + @daily_data_points_for_graph.inspect)
    Rails.logger.debug('paul' + @formatted_labels_for_graph.inspect)
    @top_tweets = fetch_top_tweets_for_user(@user)
  end

  private

  def fetch_top_tweets_for_user(user)
    user.identity.tweets
        .select('tweets.*, (coalesce(retweet_count, 0) + coalesce(quote_count, 0) + coalesce(like_count, 0) + coalesce(impression_count, 0) + coalesce(reply_count, 0) + coalesce(bookmark_count, 0)) AS total_engagement')
        .where('retweet_count > 0 OR quote_count > 0 OR like_count > 0 OR impression_count > 0 OR reply_count > 0 OR bookmark_count > 0')
        .order('total_engagement DESC')
        .limit(10)
  end


  def tweet_count_query
    Twitter::TweetCountsQuery.new(user: @user)
  end
end

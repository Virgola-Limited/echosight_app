# frozen_string_literal: true

class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(handle: params[:handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user

    # Posts/Tweet Counts
    @tweets_count = tweet_metrics_query.this_weeks_tweets_count
    @tweets_change_since_last_week = tweet_metrics_query.tweets_change_since_last_week

    if @tweets_change_since_last_week == false
      @tweets_change_since_last_week = 'Collecting data. Check back later.'
    elsif @tweets_change_since_last_week > 0
      @tweets_change_since_last_week = "#{@tweets_change_since_last_week} increase"
    elsif @tweets_change_since_last_week < 0
      @tweets_change_since_last_week = "#{@tweets_change_since_last_week.abs} decrease"
    else
      @tweets_change_since_last_week = 'No change'
    end
    ############################

    # Profile Clicks
    @profile_clicks = tweet_metrics_query.profile_clicks_count



    ############################

    # Impressions
    @impressions_count = tweet_metrics_query.impressions_count
    @impressions_change_since_last_week = tweet_metrics_query.impressions_change_since_last_week

    if @impressions_change_since_last_week == false
      @impressions_change_since_last_week = 'Collecting data. Check back later.'
    elsif @impressions_change_since_last_week > 0
      @impressions_change_since_last_week = "#{@impressions_change_since_last_week}% increase"
    elsif @impressions_change_since_last_week < 0
      @impressions_change_since_last_week = "#{@impressions_change_since_last_week.abs}% decrease"
    else
      @impressions_change_since_last_week = 'No change'
    end
    ############################

    # Followers Counts
    followers_query = Twitter::FollowersQuery.new(@user)
    @followers_count = followers_query.followers_count
    @followers_count_change_percentage_text = followers_query.followers_count_change_percentage

    if @followers_count_change_percentage_text == false
      @followers_count_change_percentage_text = 'Collecting data. Check back later.'
    end
    ############################

    # Followers Graph
    formatted_data, daily_data_points = followers_query.followers_data_for_graph
    formatted_data, daily_data_points = followers_query.followers_data_for_graph
    Rails.logger.debug("paul Controller - Formatted Labels: #{@formatted_labels_for_graph}")
    Rails.logger.debug("paul Controller - Daily Data Points: #{@daily_data_points_for_graph}")
    @formatted_labels_for_graph = formatted_data
    @daily_data_points_for_graph = daily_data_points
    Rails.logger.debug('paul @daily_data_points_for_graph' + @daily_data_points_for_graph.inspect)
    Rails.logger.debug('paul' + @formatted_labels_for_graph.inspect)
    ############################


    # Engagement Graph

    engagement_query = Twitter::EngagementQuery.new(@user)
    @total_retweets = engagement_query.total_retweets
    @total_replies = engagement_query.total_replies
    @total_likes = engagement_query.total_likes

    ############################


    # Top Posts / Tweets
    @top_tweets = tweet_metrics_query.top_tweets_for_user
    ############################
  end

  private

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(user: @user)
  end
end

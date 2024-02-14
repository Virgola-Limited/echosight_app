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
    @profile_clicks_change_since_last_week = tweet_metrics_query.profile_clicks_change_since_last_week

    if @profile_clicks_change_since_last_week == false
      @profile_clicks_change_since_last_week = 'Collecting data. Check back later.'
    elsif @profile_clicks_change_since_last_week > 0
      @profile_clicks_change_since_last_week = "#{@profile_clicks_change_since_last_week}% increase"
    elsif @profile_clicks_change_since_last_week < 0
      @profile_clicks_change_since_last_week = "#{@profile_clicks_change_since_last_week.abs}% decrease"
    else
      @profile_clicks_change_since_last_week = 'No change'
    end

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
    @followers_count = followers_query.followers_count
    @followers_count_change_percentage_text = followers_query.followers_count_change_percentage

    if @followers_count_change_percentage_text == false
      @followers_count_change_percentage_text = 'Collecting data. Check back later.'
    end
    ############################

   # Followers Graph
   formatted_follower_data, follower_daily_data_points = followers_query.followers_data_for_graph
   @follower_formatted_labels_for_graph = formatted_follower_data
   @follower_daily_data_points_for_graph = follower_daily_data_points

    ############################

    # Engagement Graph

    @engagement_rate_percentage_per_day = tweet_metrics_query.engagement_rate_percentage_per_day

    ############################

    # Impressions over Time Graph

    impressions_data = tweet_metrics_query.last_impression_counts_per_day

    # Sort the data by date to ensure it's in chronological order
    sorted_impressions_data = impressions_data.sort_by { |date, _| date }

    # Prepare data for the impressions graph
    @impression_formatted_labels_for_graph = sorted_impressions_data.map { |date, _| date.strftime('%b %d') }
    @impression_daily_data_points_for_graph = sorted_impressions_data.map { |_, count| count }
    # Rails.logger.debug('paul @formatted_labels_for_graph' + @formatted_labels_for_graph.inspect)
    # Rails.logger.debug('paul @daily_data_points_for_graph' + @daily_data_points_for_graph.inspect)

    ############################

    # Profile Conversion Rate
    @profile_clicks_data = tweet_metrics_query.profile_clicks_count_per_day
    @followers_data = followers_query.daily_followers_count



    # Calculate profile conversion rate per day
    @conversion_rates_data_for_graph = @profile_clicks_data.map do |date, clicks|
      followers = @followers_data[date] || 0
      conversion_rate = clicks > 0 ? (followers.to_f / clicks) * 100 : 0
      {
        date: date,
        conversion_rate: conversion_rate,
        followers: followers,
        profile_clicks: clicks
      }
    end

    # Top Posts / Tweets
    @top_tweets = tweet_metrics_query.top_tweets_for_user
    ############################
  end

  private

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(user: @user)
  end

  def followers_query
    Twitter::FollowersQuery.new(@user)
  end
end

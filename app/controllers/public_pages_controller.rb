# frozen_string_literal: true

class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(handle: params[:handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user

    # Posts/Tweet Counts
    @tweets_count = tweet_count_query.this_weeks_tweets_count

    @tweets_change_since_last_week = tweet_count_query.tweets_change_since_last_week
    if @tweets_change_since_last_week.is_a?(Integer)
      @tweets_change_since_last_week = @tweets_change_since_last_week.to_s
    else
      @days_until_last_weeks_data_available = tweet_count_query.days_until_last_weeks_data_available
      @tweets_change_since_last_week = "Collecting data. Check back later in #{@days_until_last_weeks_data_available} days."
    end
    ############################

    # Impressions
    @impressions_count = impressions_query.impressions_count
    @impressions_change_since_last_week = impressions_query.impressions_change_since_last_week

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

    # Followers
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
    ############################

    # Top Posts / Tweets
    @top_tweets = impressions_query.top_tweets_for_user
    ############################
  end

  private

  def tweet_count_query
    Twitter::TweetCountsQuery.new(user: @user)
  end

  def impressions_query
    Twitter::ImpressionsQuery.new(@user)
  end
end

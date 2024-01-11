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
    @followers_count = Twitter::FollowersQuery.new(@user).followers_count
    @followers_count_change_percentage_text = Twitter::FollowersQuery.new(@user).followers_count_change_percentage
    @followers_data_for_graph = Twitter::FollowersQuery.new(@user).followers_data_for_graph
  end

  def tweet_count_query
    Twitter::TweetCountsQuery.new(user: @user)
  end
end

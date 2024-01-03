class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(twitter_handle: params[:twitter_handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user

    @tweets_count = Twitter::TweetCountsQuery.new(@user).this_weeks_tweets_count
    @tweets_change_since_last_week = 'TBC'

    raise 'Missing user' unless @user
  end
end

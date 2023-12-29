class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(twitter_handle: params[:twitter_handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user

    query = TweetCountsQuery.new(@user)
    @tweets_count = query.this_weeks_tweets_count
    @tweets_change_since_last_week = query.calculate_tweets_change

    raise 'Missing user' unless @user
  end
end

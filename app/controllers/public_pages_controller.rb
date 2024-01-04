class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(twitter_handle: params[:twitter_handle])
    @user = identity.user if identity.present?

    raise 'Missing user' unless @user
    if tweet_count_query.data_stale?
      @tweets_count = "Data is being fetched. Check back later."
    else
      @tweets_count = tweet_count_query.this_weeks_tweets_count
    end

    @tweets_change_since_last_week = tweet_count_query.tweets_change_since_last_week
    if @tweets_change_since_last_week.is_a?(Integer)
      @tweets_change_since_last_week = "#{@tweets_change_since_last_week}"
    else
      'bb'
    end

    raise 'Missing user' unless @user
  end

  def tweet_count_query
    Twitter::TweetCountsQuery.new(user: @user)
  end
end

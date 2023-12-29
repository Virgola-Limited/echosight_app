class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(twitter_handle: params[:twitter_handle])
    @user = identity.user if identity.present?

    # WIP: only working with me
    # hit 24 limit on free request 25 per day
    # Rails.logger.debug('paul' + x_client.get("users/me").inspect)

    # Fetch tweets from the last week
    @tweets_count = fetch_tweets_count_from_last_week(@user)

    # Calculate the change since last week
    # @tweets_change_since_last_week = calculate_tweets_change(@user)
  end

  def fetch_tweets_count_from_last_week(user)
    # Set up the endpoint and the parameters
    endpoint = 'tweets/search/recent'
    params = {
      'query' => "from:#{user.twitter_handle}",
      'start_time' => 1.week.ago.utc.iso8601,
      'tweet.fields' => 'created_at'
    }

    # Construct the full URL with encoded parameters
    # uri = URI.join(x_client.base_url, endpoint)
    # uri.query = URI.encode_www_form(params)
    full_endpoint = "#{endpoint}?#{URI.encode_www_form(params)}"

    # Use the client's method to perform the GET request
    Rails.logger.debug('paul full_endpoint' + full_endpoint.inspect)

    response = x_client.get(full_endpoint)
    response['meta']['result_count']
  end

  def calculate_tweets_change(user)
    # This method should compare the count of tweets from the last week to the week before
    # Placeholder logic below
    last_week_count = fetch_tweets_count_from_last_week(user)
    previous_week_count = fetch_tweets_count_from_two_weeks_ago(user)

    last_week_count - previous_week_count
  end

  def fetch_tweets_count_from_two_weeks_ago(user)
    endpoint = 'tweets/search/recent'
    params = {
      'query' => "from:#{user.twitter_handle}",
      'start_time' => 2.week.ago.utc.iso8601,
      'end_time' => 1.weeks.ago.utc.iso8601,
      'tweet.fields' => 'created_at'
    }

    # Fetch tweets from two weeks ago up to last week
    full_endpoint = "#{endpoint}?#{URI.encode_www_form(params)}"

    # tweets = x_client.get("tweets/search/recent", {
    #   query: "from:#{user.twitter_handle}",
    #   start_time: 2.weeks.ago.utc.iso8601,
    #   end_time: 1.week.ago.utc.iso8601,
    #   "tweet.fields": "created_at"
    # })

    response = x_client.get(full_endpoint)
    response['meta']['result_count']
  end

  def x_client
    # if else may not be needed suggested by ChatGPT. will leave in for now
    x_credentials = if @user
                      # User context
                      {
                        api_key: ENV['TWITTER_CONSUMER_API_KEY'],
                        api_key_secret: ENV['TWITTER_CONSUMER_API_SECRET'],
                        access_token: @user.identity.token,
                        access_token_secret: @user.identity.secret
                      }
                    else
                      # Application context (Bearer Token)
                      {
                        bearer_token: ENV['TWITTER_BEARER_TOKEN']
                      }
                    end
    X::Client.new(**x_credentials)
  end
end

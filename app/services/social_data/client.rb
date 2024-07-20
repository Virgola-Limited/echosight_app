# frozen_string_literal: true

module SocialData
  class Client
    attr_reader :user

    # perhaps removing this or increase it a very large amount
    MAXIMUM_TWEETS = 2000

    def initialize(user: nil)
      @user = user
    end

    def api_key
      Rails.application.credentials.social_data[:api_key]
    end
    # https://socialdata.gitbook.io/docs/twitter-tweets/retrieve-search-results-by-keyword
    # https://github.com/igorbrigadir/twitter-advanced-search
    def search_tweets(params = {}, single_request = false)
      endpoint = 'search'

      # Ensure the query includes -filter:replies
      # if params[:query] && !params[:query].include?("-filter:replies")
      #   params[:query] += " -filter:replies"
      # end

      received_tweet_count = 0
      all_tweets = []
      while received_tweet_count < MAXIMUM_TWEETS
        response = make_api_call(endpoint, params, :oauth2)
        break unless response['tweets'] && !response['tweets'].empty?

        tweets_with_user_data = response['tweets'].map do |tweet|
          tweet.merge('user' => extract_user_data(tweet))
        end

        all_tweets.concat(tweets_with_user_data)
        received_tweet_count += response['tweets'].size
        break if single_request || response['next_cursor'].nil?

        params['cursor'] = response['next_cursor']
      end

      if received_tweet_count >= MAXIMUM_TWEETS
        error_details = { error: "Reached maximum tweet count of #{MAXIMUM_TWEETS} for endpoint: #{endpoint}, params: #{params.to_s}" }
        ExceptionNotifier.notify_exception(StandardError.new("Maximum tweets limit reached"), data: error_details)
      end

      { 'tweets' => all_tweets }
    end

    def fetch_user_details(user_id)
      endpoint = "user/#{user_id}"
      params = {}

      make_api_call(endpoint, params, :oauth2)
    end


    # TODO: Internalize the next_token handling to prevent
    # pullling too many tweets
    def fetch_user_tweets(next_token = nil)
      endpoint = "user/#{user.identity.uid}/tweets"
      params = {
        'cursor' => next_token
      }

      make_api_call(endpoint, params, :oauth2)
    end

    def fetch_user_with_metrics
      endpoint = "user/#{user.identity.uid}"
      params = {}

      make_api_call(endpoint, params, :oauth2)
    end

    def fetch_tweets_by_ids(tweet_ids)
      tweets = tweet_ids.map do |tweet_id|
        fetch_tweet_by_id(tweet_id)
      end
      { 'tweets' => tweets.compact }
    end

    private

    def extract_user_data(tweet)
      tweet['user'] || {}
    end

    def fetch_tweet_by_id(tweet_id)
      endpoint = 'statuses/show'
      params = {
        'id' => tweet_id
      }
      make_api_call(endpoint, params, :oauth2)
    end

    def make_api_call(endpoint, params, _auth_type)
      uri = URI("https://api.socialdata.tools/twitter/#{endpoint}")

      # remove params with empty values
      params = params.reject { |_k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }

      uri.query = URI.encode_www_form(params) unless params.nil? || params.empty?

      # Set up the request
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{api_key}" # Add appropriate authorization header

      # Perform the request
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      # Handle the response
      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "HTTP request failed: #{response.code} - #{response.message}, uri: #{uri.inspect}, params: #{params.inspect}"
      end

      JSON.parse(response.body)
    end
  end
end

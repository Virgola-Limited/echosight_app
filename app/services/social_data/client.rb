# frozen_string_literal: true

module SocialData
  class Client
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def api_key
      Rails.application.credentials.social_data[:api_key]
    end

    # TODO: need to iterate over tweets until we reach one we already have
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

    def fetch_tweets_by_ids(tweet_ids, include_non_public_metrics = false)
      tweets = tweet_ids.map do |tweet_id|
        fetch_tweet_by_id(tweet_id, include_non_public_metrics)
      end
      tweets.compact
    end

    private

    def fetch_tweet_by_id(tweet_id, include_non_public_metrics = false)
      endpoint = "statuses/show"
      params = {
        'id' => tweet_id
      }

      make_api_call(endpoint, params, :oauth2)
    end


    def make_api_call(endpoint, params, _auth_type)
      uri = URI("https://api.socialdata.tools/twitter/#{endpoint}")

      # remove params with empty values
      params = params.reject { |_k, v| v.nil? || v.empty? }
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
        raise StandardError, "HTTP request failed: #{response.code} - #{response.message}"
      end

      JSON.parse(response.body)
    end
  end
end

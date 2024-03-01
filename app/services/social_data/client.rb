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
    def fetch_user_tweets(_next_token = nil)
      endpoint = "user/#{user.identity.uid}/tweets"
      params = {
        # 'cursor' => xxx
      }

      make_api_call(endpoint, params, :oauth2)
    end

    private

    def make_api_call(endpoint, _params, _auth_type, _version = :v2)
      # Construct the API request URL
      uri = URI("https://api.socialdata.tools/twitter/#{endpoint}") # Replace 'socialdata.api.endpoint' with the actual API endpoint

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

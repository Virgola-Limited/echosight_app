module SocialData
  class Client
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def access_token
      '120|gEVUlsk53tYfMrKJDM8ZISgPXinys4SdI2taW0FW6ba1d55a'
    end

    def fetch_new_tweets(next_token = nil)
      endpoint = "user/#{user.identity.uid}/tweets"
      params = {
        # 'cursor' => xxx
      }

      make_api_call(endpoint, params, :oauth2)
    end

    private

    def make_api_call(endpoint, params, auth_type, version = :v2)
      # Construct the API request URL
      uri = URI("https://api.socialdata.tools/twitter/#{endpoint}")  # Replace 'socialdata.api.endpoint' with the actual API endpoint

      # Set up the request
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{access_token}"  # Add appropriate authorization header

      # Perform the request
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      # Handle the response
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        raise StandardError, "HTTP request failed: #{response.code} - #{response.message}"
      end
    end
  end
end

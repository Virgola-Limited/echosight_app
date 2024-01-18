# frozen_string_literal: true

# Not used as we store the bearer token in the .env file
# Could be useful later
module Twitter
class FetchBearerTokenService
  def self.fetch_bearer_token
    consumer_key = Rails.application.credentials.dig(:twitter, :consumer_api_key)
    consumer_secret = Rails.application.credentials.dig(:twitter, :consumer_api_secret)

    # Base64 encode your consumer key and secret
    credentials = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")

    response = Faraday.post('https://api.twitter.com/oauth2/token') do |req|
      req.headers['Authorization'] = "Basic #{credentials}"
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
      req.body = 'grant_type=client_credentials'
    end

    # Parse and return the bearer token from the response body
    JSON.parse(response.body)['access_token']
  end
end
end
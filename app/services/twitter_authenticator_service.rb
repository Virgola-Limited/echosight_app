# Not used as we store the bearer token in the .env file
# Could be useful later
class TwitterAuthenticatorService
  def self.fetch_bearer_token
    consumer_key = ENV['TWITTER_CONSUMER_API_KEY']
    consumer_secret = ENV['TWITTER_CONSUMER_API_SECRET']

    # Base64 encode your consumer key and secret
    credentials = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")

    response = Faraday.post('https://api.twitter.com/oauth2/token') do |req|
      req.headers['Authorization'] = "Basic #{credentials}"
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8'
      req.body = 'grant_type=client_credentials'
    end

    # Parse and return the bearer token from the response body
    Rails.logger.debug('paul response.body' + response.body.inspect)
    JSON.parse(response.body)['access_token']
  end
end

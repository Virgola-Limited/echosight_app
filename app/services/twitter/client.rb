require 'x'

module Twitter
  class Client
    attr_reader :user

    def initialize(user)
      @user = user
      setup_client
    end

    def setup_client
      @x_client = X::Client.new(
        api_key: Rails.application.credentials.dig(:twitter, :consumer_api_key),
        api_key_secret: Rails.application.credentials.dig(:twitter, :consumer_api_secret),
        access_token: user.oauth_credential.token,
        access_token_secret: user.oauth_credential.secret
      )
    end

    def post_tweet(text, media_ids = [])
      # Simplify the tweet text to a basic example
      simple_text = "Hello, World! (from @gem)"
      params = { text: simple_text }
      params[:media_ids] = media_ids if media_ids.present?

      puts "Sending tweet with params: #{params.to_json}"  # Log the params

      response = @x_client.post("tweets", params.to_json)

      puts "API response: #{response.inspect}"  # Log the response

      response
    rescue X::Error => e
      handle_x_error(e)
    end

    private

    def handle_x_error(error)
      puts "Failed to post tweet: #{error.message}"
      puts "Error details: #{error.inspect}"  # Log the full error details
      nil
    end
  end
end

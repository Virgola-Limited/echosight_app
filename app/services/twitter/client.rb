require 'x'
require 'x/media_uploader'
require 'open-uri'

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
      params = { text: text }
      params[:media] = { media_ids: media_ids } if media_ids.present?

      puts "Sending tweet with params: #{params.to_json}"  # Log the params

      response = @x_client.post("tweets", params.to_json)

      puts "API response: #{response.inspect}"  # Log the response

      response
    rescue X::Error => e
      handle_x_error(e)
    end

    def upload_media(image_url)
      file = URI.open(image_url).path
      media_category = "tweet_image" # Adjust as needed
      response = X::MediaUploader.upload(client: @x_client, file_path: file, media_category: media_category)

      if response["media_id_string"]
        response["media_id_string"]
      else
        raise StandardError.new("Failed to upload media: #{response.inspect}")
      end
    rescue StandardError => e
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

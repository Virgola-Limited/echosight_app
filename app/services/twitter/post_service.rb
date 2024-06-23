module Twitter
  class PostService
    def initialize(user, text)
      @user = user
      @text = text
      @client = Twitter::Client.new(user)
    end

    def call
      # if @user.oauth_credential.expired_or_expiring_soon?
      #   puts "OAuth token has expired or is expiring soon. Please reconnect your Twitter account."
      #   return nil
      # end

      response = @client.post_tweet(@text)
      if response && response['data']
        puts "Tweet posted successfully: #{response['data']['text']}"
      else
        puts "Failed to post tweet: #{response&.dig('errors') || 'Unknown error'}"
      end
      response
    rescue StandardError => e
      puts "Failed to post tweet: #{e.message}"
      nil
    end
  end
end

def test_service
  user = User.first
  text = "Hello world! This is a tweet from a service."
  service = Twitter::PostService.new(user, text)
  response = service.call
end

# curl -X POST "https://api.twitter.com/2/tweets" \
#      -H "Authorization: Bearer RGFLSzI0NVlVYVpsOU9iNzNGZUNienhWLWx0RjZyeldfaDlDZGtfZGtlT1hQOjE3MTkxMjE0ODgwNzM6MToxOmF0OjE" \
#      -H "Content-Type: application/json" \
#      -d '{"text":"Hello world! This is a test tweet."}'

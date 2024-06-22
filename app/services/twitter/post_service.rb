# app/services/twitter_post_service.rb
module Twitter
  class PostService
    def initialize(user, text)
      @user = user
      @text = text
      @client = Twitter::Client.new(user)
    end

    def call
      response = @client.post_tweet(@text)
      puts "Tweet posted successfully: #{response['data']['text']}"
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
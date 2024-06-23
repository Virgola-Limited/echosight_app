module Twitter
  class PostService
    def initialize(user, text)
      @user = user
      @text = text
      @client = Twitter::Client.new(user)
    end

    def call
      response = @client.post_tweet(@text)
      unless response && response['data']
        ExceptionNotifier.notify_exception(
          StandardError.new("Failed to post tweet: #{response
            &.dig('errors') || 'Unknown error'}"),
          data: { user_id: @user.id }
        )
      end
      response
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { user_id: @user.id })
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

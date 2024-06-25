module Twitter
  class PostService
    def initialize(user, text, image_url = nil)
      @user = user
      @text = image_url.present? ? "#{text} #{image_url}" : text
      @client = Twitter::Client.new(user)
    end

    def call
      response = @client.post_tweet(@text)
      unless response && response['data']
        ExceptionNotifier.notify_exception(
          StandardError.new("Failed to post tweet: #{response&.dig('errors') || 'Unknown error'}"),
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

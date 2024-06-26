module Twitter
  class PostService
    def initialize(user, text, image_url = nil)
      @user = user
      @text = text
      @image_url = image_url
      @client = Twitter::Client.new(user)
    end

    def call
      media_id = upload_image if @image_url
      response = @client.post_tweet(@text, media_id ? [media_id] : [])

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

    private

    def upload_image
      media_id = @client.upload_media(@image_url)
      unless media_id
        ExceptionNotifier.notify_exception(StandardError.new('Failed to upload media'), data: { image_url: @image_url })
        return nil
      end
      media_id
    end
  end
end
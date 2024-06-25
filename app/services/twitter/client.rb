module Twitter
  class Client
    attr_reader :user, :api

    def initialize(user = nil)
      @user = user
      @api = Twitter::Api.new(user)
    end

    def post_tweet(text, media_ids = [])
      endpoint = 'tweets'
      params = { 'text' => text }
      params['media'] = { 'media_ids' => media_ids } if media_ids.present?
      api.make_api_call(endpoint, params, :oauth2)
    end

    def upload_media(image_url)
      endpoint = 'media/upload'
      file = URI.open(image_url)
      params = { 'media' => file.read }
      response = api.make_upload_api_call(endpoint, params)
      response['media_id'] if response && response['media_id']
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { image_url: image_url })
      nil
    end

    # other methods...
  end
end

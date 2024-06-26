module Twitter
  class Api
    attr_reader :user, :oauth

    def initialize(user)
      @user = user
      @oauth = Twitter::Oauth.new(user)
    end

    def make_api_call(endpoint, params, auth_type, version)
      uri = URI.join(base_url(version), endpoint)
      request = Net::HTTP::Post.new(uri)
      auth_token = oauth.user_token_or_app_token(version, auth_type)
      request['Authorization'] = "OAuth #{auth_token}"
      request['Content-Type'] = 'application/json'
      request.body = params.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      handle_response(response, endpoint, params, auth_type)
    rescue StandardError => e
      ErrorHandling.handle_api_error(e, endpoint, params, auth_type, user)
    end

    def make_upload_api_call(endpoint, params)
      uri = URI.join('https://upload.twitter.com/1.1/', endpoint)
      request = Net::HTTP::Post.new(uri)
      auth_token = oauth.user_token_or_app_token(:v1_1, :oauth1)
      request['Authorization'] = "OAuth #{auth_token}"
      request.set_form({ 'media' => params['media'] }, 'multipart/form-data')

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      handle_response(response, endpoint, params, :oauth1)
    rescue StandardError => e
      ErrorHandling.handle_api_error(e, endpoint, params, :oauth1, user)
    end

    private

    def base_url(version = :v2)
      "https://api.twitter.com/#{version == :v1_1 ? '1.1' : '2'}/"
    end

    def handle_response(response, endpoint, params, auth_type)
      if response.code.to_i == 403
        ErrorHandling.handle_forbidden_error(user)
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      ErrorHandling.handle_api_error(e, endpoint, params, auth_type, user)
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { endpoint: endpoint, response_body: response.body })
      raise e
    end
  end
end
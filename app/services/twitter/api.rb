module Twitter
  class Api
    attr_reader :user, :oauth

    def initialize(user)
      @user = user
      @oauth = Twitter::Oauth.new(user)
    end

    def make_api_call(endpoint, params, auth_type, version = :v2)
      oauth.refresh_token_if_needed if user

      uri = URI.join(base_url(version), endpoint)
      request = Net::HTTP::Post.new(uri)
      bearer_token = oauth.user_token_or_app_token(version, auth_type)
      request['Authorization'] = "Bearer #{bearer_token}"
      request['Content-Type'] = 'application/json'
      request.body = params.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      handle_response(response, endpoint, params, auth_type)
    rescue StandardError => e
      ErrorHandling.handle_api_error(e, endpoint, params, auth_type, user)
    end

    private

    def base_url(version = :v2)
      version == :v1_1 ? 'https://api.twitter.com/1.1/' : 'https://api.twitter.com/2/'
    end

    def handle_response(response, endpoint, params, auth_type)
      if response.code.to_i == 403
        ErrorHandling.handle_forbidden_error(user)
      end

      JSON.parse(response.body)
    end
  end
end

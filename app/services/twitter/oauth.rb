module Twitter
  class Oauth
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def refresh_token_if_needed
      return unless user&.identity&.oauth_credential&.expired_or_expiring_soon?

      refresh_token(user.identity.oauth_credential)
    end

    def refresh_token(oauth_credential)
      refreshed_credentials = refresh_oauth_token(oauth_credential)
      oauth_credential.update!(
        token: refreshed_credentials[:token],
        refresh_token: refreshed_credentials[:refresh_token],
        expires_at: Time.at(refreshed_credentials[:expires_at])
      )
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { credential_id: oauth_credential.id, refresh_token: oauth_credential.refresh_token })
    end

    def user_token_or_app_token(version, auth)
      if user && user.identity.oauth_credential.token.present?
        user.identity.oauth_credential.token
      else
        application_context_credentials(version, auth)[:bearer_token]
      end
    end

    private

    def refresh_oauth_token(oauth_credential)
      uri = URI('https://api.twitter.com/2/oauth2/token')
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/x-www-form-urlencoded'

      client_id = Rails.application.credentials.dig(:twitter, :oauth2_client_id)
      client_secret = Rails.application.credentials.dig(:twitter, :oauth2_client_secret)
      credentials = "#{client_id}:#{client_secret}"
      encoded_credentials = Base64.strict_encode64(credentials)

      request['Authorization'] = "Basic #{encoded_credentials}"
      request.body = URI.encode_www_form({
        'refresh_token' => oauth_credential.refresh_token,
        'grant_type' => 'refresh_token'
      })

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("Failed to refresh token for credential ID #{oauth_credential.id}: #{response.body}")
        return nil # Or you could return an empty hash or some default value
      end

      new_creds = JSON.parse(response.body)

      {
        token: new_creds['access_token'],
        refresh_token: new_creds['refresh_token'], # Twitter may or may not return a new refresh token
        expires_at: Time.now + new_creds['expires_in'].to_i
      }
    rescue StandardError => e
      Rails.logger.error("Exception when trying to refresh token for credential ID #{oauth_credential.id}: #{e.message}")
      nil # Or you could return an empty hash or some default value
    end

    def application_context_credentials(version, auth)
      credentials = { base_url: base_url(version) }

      case auth
      when :oauth2
        credentials[:bearer_token] = Rails.application.credentials.dig(:twitter, :bearer_token)
      when :oauth1
        credentials[:api_key] = Rails.application.credentials.dig(:twitter, :consumer_api_key)
        credentials[:api_key_secret] = Rails.application.credentials.dig(:twitter, :consumer_api_secret)
      end

      credentials
    end

    def base_url(version = :v2)
      version == :v1_1 ? 'https://api.twitter.com/1.1/' : 'https://api.twitter.com/2/'
    end
  end
end

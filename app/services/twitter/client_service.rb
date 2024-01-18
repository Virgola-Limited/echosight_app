# frozen_string_literal: true

module Twitter
  class ClientService
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def client(version: :v2, auth: :oauth2)
      X::Client.new(**credentials(version, auth))
    end

    private

    def credentials(version, auth)
      if user
        user_context_credentials(version)
      else
        application_context_credentials(version, auth)
      end
    end

    #  Not sure this is working. Assume its not when you first use it
    def user_context_credentials(version)
      results = {
        bearer_token: user.identity.bearer_token, # OAUTH2
        base_url: base_url(version)
      }
      results
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

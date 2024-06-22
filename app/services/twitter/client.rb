# frozen_string_literal: true

# rubocop :disable Metrics/ClassLength
module Twitter
  class Client
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    def post_tweet(text)
      endpoint = 'tweets'
      params = { 'text' => text }
      make_api_call(endpoint, params, :oauth2)
    end

    # https://developer.twitter.com/en/portal/products/basic

    # | Endpoint            | #Requests | Window of time | Per      | Part of the Tweet pull cap? | Effective 30-day limit |
    # |---------------------|-----------|----------------|----------|-----------------------------|------------------------|
    # | GET_2_users_param   | 500       | 24 hours       | per user | no                          | 15,000                 |
    # | GET_2_users_param   | 100       | 24 hours       | per app  | no                          | 3,000                  |
    def fetch_user_with_metrics
      raise "Not needed as we get this via tweets"
      endpoint = "users/#{user.identity.uid}"
      params = { 'user.fields' => 'public_metrics' }
      make_api_call(endpoint, params, :oauth1)
    end

    # | Endpoint                  | #Requests | Window of time | Per      | Part of the Tweet pull cap? | Effective 30-day limit |
    # |---------------------------|-----------|----------------|----------|-----------------------------|------------------------|
    # | GET_2_users_param_tweets  | 10        | 15 minutes     | per app  | yes                         | 10,000                 |
    # | GET_2_users_param_tweets  | 5         | 15 minutes     | per user | yes                         | 10,000                 |
    def fetch_user_tweets(next_token = nil)
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics,non_public_metrics',
        'pagination_token' => next_token,
        'max_results' => 100
      }.compact

      make_api_call(endpoint, params, :oauth1)
    end

    def fetch_tweets_by_ids(tweet_ids)
      endpoint = 'tweets'
      fields = 'created_at,public_metrics'

      params = {
        'ids' => tweet_ids.join(','), # Convert to a comma-separated string
        'tweet.fields' => fields
      }

      make_api_call(endpoint, params, :oauth1)
    end

    def fetch_rate_limit_data
      endpoint = 'application/rate_limit_status.json'
      params = {} # Add necessary parameters if needed
      make_api_call(endpoint, params, :oauth2, :v1_1) # Using OAuth1 for Twitter API v1.1
    end

    private

    def refresh_token_if_needed(oauth_credential)
      Rails.logger.debug('paul' + 'refreshing token'.inspect)
      return unless oauth_credential.expired_or_expiring_soon?

      refreshed_credentials = refresh_oauth_token(oauth_credential)
      oauth_credential.update!(
        token: refreshed_credentials[:token],
        refresh_token: refreshed_credentials[:refresh_token],
        expires_at: Time.at(refreshed_credentials[:expires_at])
      )
    end

    def refresh_oauth_token(oauth_credential)
      uri = URI('https://api.twitter.com/2/oauth2/token')
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/x-www-form-urlencoded'

      # Combine client ID and secret, then Base64-encode for Basic Auth
      client_id = Rails.application.credentials.dig(:twitter, :oauth2_client_id)
      client_secret = Rails.application.credentials.dig(:twitter, :oauth2_client_secret)
      credentials = "#{client_id}:#{client_secret}"
      encoded_credentials = Base64.strict_encode64(credentials)

      # Include the encoded credentials in the Authorization header
      request['Authorization'] = "Basic #{encoded_credentials}"

      # Set the request body with the refresh token and grant type
      request.body = URI.encode_www_form({
                                           'refresh_token' => oauth_credential.refresh_token,
                                           'grant_type' => 'refresh_token'
                                         })

      # Perform the request
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      # Parse the response
      raise "Failed to refresh token: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      new_creds = JSON.parse(response.body)

      # Return the new token details
      {
        token: new_creds['access_token'],
        refresh_token: new_creds['refresh_token'], # Twitter may or may not return a new refresh token
        expires_at: Time.now + new_creds['expires_in'].to_i
      }

      # Raise an error with the response body
    end

    def handle_api_error(e, endpoint, params, auth_type)
      if e.message == 'Unauthorized' && user
        refresh_token_if_needed(user.identity.oauth_credential)
        retry_api_call(endpoint, params, auth_type)
      elsif e.is_a?(X::TooManyRequests) && e.rate_limit
        rate_limit = e.rate_limit # Assuming the error object has a `rate_limit` attribute with X::RateLimit instance
        message = "Rate Limit Exceeded: Type #{rate_limit.type}, Limit #{rate_limit.limit}, Remaining #{rate_limit.remaining}, Reset in #{rate_limit.reset_in} seconds"
        request_info = "Endpoint: #{endpoint}, Params: #{params.to_json}"

        # Send rate limit info and request details to Slack
        Notifications::SlackNotifier.call(message: "#{message}, Request Info: #{request_info}", channel: :xratelimit)


        # Re-raise the error to maintain the original flow
        raise e
      elsif e.message.start_with?('Twitter API Error:')
        request_info = if auth_type == :oauth1
                         "Full URL: #{base_url(determine_api_version(endpoint))}#{endpoint}?#{URI.encode_www_form(params)}"
                       else
                         # For POST requests or when detailed post data is needed
                         "Endpoint: #{endpoint}, Data: #{params.to_json}"
                       end
        error_details = {
          error: e.message,
          auth_type: auth_type.to_s,
          api_version: determine_api_version(endpoint),
          endpoint:,
          request_info:, # Added full request details
          user_info: user_info_for_error
        }

        ExceptionNotifier.notify_exception(e, data: error_details)
        e.instance_variable_set(:@error_details, error_details)
        raise e
      else
        request_info = "Endpoint: #{endpoint}, Params: #{params.to_json}"
        error_details = {
          error: e.message,
          auth_type: auth_type.to_s,
          api_version: determine_api_version(endpoint),
          request_info:, # Added request details
          user_info: user_info_for_error
        }

        ExceptionNotifier.notify_exception(
          StandardError.new("Twitter API Error: #{e.message}"),
          data: error_details
        )

        e.instance_variable_set(:@error_details, error_details)
      end
    end

    def client(version:, auth: :oauth2)
      X::Client.new(**credentials(version, auth))
    end

    def make_api_call(endpoint, params, auth_type, version = :v2)
      refresh_token_if_needed(user.identity.oauth_credential) if user

      uri = URI.join(base_url(version), endpoint)
      request = Net::HTTP::Post.new(uri)
      bearer_token = credentials(version, auth_type)[:bearer_token]
      puts "Bearer token: #{bearer_token}" # Debugging
      request['Authorization'] = "Bearer #{bearer_token}"
      request['Content-Type'] = 'application/json'
      request.body = params.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      puts "Response: #{response.body}" # Debugging

      JSON.parse(response.body)
    rescue X::Error => e
      handle_api_error(e, endpoint, params, auth_type)
    end

    def retry_api_call(endpoint, params, auth_type)
      # Dont check refresh token this time
      client(auth: auth_type).get("#{endpoint}?#{URI.encode_www_form(params)}")
    rescue X::Error => e
      handle_api_error(e, endpoint, params, auth_type)
    end

    def determine_api_version(endpoint)
      endpoint.include?('/1.1/') ? 'v1.1' : 'v2'
    end

    def user_info_for_error
      return "User ID: #{user.identity.uid}, Email: #{user.email}" if user

      'Application Context'
    end

    def credentials(version, auth)
      if user
        user_context_credentials(version)
      else
        application_context_credentials(version, auth)
      end
    end

    def user_context_credentials(version)
      {
        bearer_token: user.identity.oauth_credential.token,
        base_url: base_url(version)
      }
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

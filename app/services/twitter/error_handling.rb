module Twitter
  class ErrorHandling
    def self.handle_api_error(e, endpoint, params, auth_type, user)
      if e.message == 'Unauthorized' && user
        Twitter::Oauth.new(user).refresh_token_if_needed
        retry_api_call(endpoint, params, auth_type)
      elsif e.is_a?(X::TooManyRequests) && e.rate_limit
        handle_rate_limit_error(e, endpoint, params)
      elsif e.message.start_with?('Twitter API Error:')
        notify_twitter_error(e, endpoint, params, auth_type, user)
      else
        notify_generic_error(e, endpoint, params, auth_type, user)
      end
    end

    def self.handle_rate_limit_error(e, endpoint, params)
      rate_limit = e.rate_limit # Assuming the error object has a `rate_limit` attribute with X::RateLimit instance
      message = "Rate Limit Exceeded: Type #{rate_limit.type}, Limit #{rate_limit.limit}, Remaining #{rate_limit.remaining}, Reset in #{rate_limit.reset_in} seconds"
      request_info = "Endpoint: #{endpoint}, Params: #{params.to_json}"

      # Send rate limit info and request details to Slack
      Notifications::SlackNotifier.call(message: "#{message}, Request Info: #{request_info}", channel: :xratelimit)

      # Re-raise the error to maintain the original flow
      raise e
    end

    def self.notify_twitter_error(e, endpoint, params, auth_type, user)
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
        user_info: user_info_for_error(user)
      }

      ExceptionNotifier.notify_exception(e, data: error_details)
      e.instance_variable_set(:@error_details, error_details)
      raise e
    end

    def self.notify_generic_error(e, endpoint, params, auth_type, user)
      request_info = "Endpoint: #{endpoint}, Params: #{params.to_json}"
      error_details = {
        error: e.message,
        auth_type: auth_type.to_s,
        api_version: determine_api_version(endpoint),
        request_info:, # Added request details
        user_info: user_info_for_error(user)
      }

      ExceptionNotifier.notify_exception(
        StandardError.new("Twitter API Error: #{e.message}"),
        data: error_details
      )

      e.instance_variable_set(:@error_details, error_details)
    end

    def self.handle_forbidden_error(user)
      ExceptionNotifier.notify_exception(
        StandardError.new('Forbidden error encountered. Please check your app permissions.'),
        data: { user_info: user_info_for_error(user) }
      )
    end

    def self.retry_api_call(endpoint, params, auth_type)
      # Don't check refresh token this time
      client(auth: auth_type).get("#{endpoint}?#{URI.encode_www_form(params)}")
    rescue X::Error => e
      handle_api_error(e, endpoint, params, auth_type)
    end

    def self.determine_api_version(endpoint)
      endpoint.include?('/1.1/') ? 'v1.1' : 'v2'
    end

    def self.user_info_for_error(user)
      return "User ID: #{user.identity.uid}, Email: #{user.email}" if user

      'Application Context'
    end
  end
end

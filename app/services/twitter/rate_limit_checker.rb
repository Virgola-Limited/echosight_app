# frozen_string_literal: true

module Twitter
  class RateLimitChecker
    attr_reader :rate_limit_data

    def initialize
    end

    def call
      fetch_rate_limit_data
      process_rate_limit_data
    end

    private

    def fetch_rate_limit_data
      return rate_limit_data if rate_limit_data
      # refactor to use twitter client
      endpoint = 'application/rate_limit_status.json'
      @rate_limit_data = twitter_client.get(endpoint) # Assuming the client is configured for OAuth2
    end

    def twitter_client
      @twitter_client ||= Client.new.client(version: :v1_1)
    end

    def process_rate_limit_data
      response = fetch_rate_limit_data

      # Process the response to extract and display rate limit information
      if response['resources']
        response['resources'].each do |resource, endpoints|
          endpoints.each do |endpoint, data|
            if data['remaining'] == 0
              puts "Resource: #{resource} Endpoint: #{endpoint}, Limit: #{data['limit']}, Remaining: #{data['remaining']}, Reset: #{Time.at(data['reset'])}"
            end
          end
        end
      end
      p 'Any maxed out results should show above'
    end
  end
end

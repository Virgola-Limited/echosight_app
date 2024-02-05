module Twitter
  class RateLimitChecker
    attr_reader :rate_limit_data, :twitter_client

    def initialize
      @twitter_client = Twitter::Client.new # Pass user if needed
    end

    def call
      fetch_rate_limit_data
      process_rate_limit_data
    end

    private

    def fetch_rate_limit_data
      return @rate_limit_data if @rate_limit_data
      @rate_limit_data = twitter_client.fetch_rate_limit_data
    end

    def process_rate_limit_data
      response = @rate_limit_data

      if response && response['resources']
        response['resources'].each do |resource, endpoints|
          endpoints.each do |endpoint, data|
            if data['remaining'] == 0
              puts "Resource: #{resource} Endpoint: #{endpoint}, Limit: #{data['limit']}, Remaining: #{data['remaining']}, Reset: #{Time.at(data['reset'])}"
            end
          end
        end
      else
        puts 'No rate limit data available'
      end
    end
  end
end

module Twitter
  class RateLimitChecker
    attr_reader :rate_limit_data, :user, :client

    def initialize(user = nil, client: nil)
      # @user = user
      @client = client || Twitter::Client.new#(user)
    end

    def call
      fetch_rate_limit_data
      process_rate_limit_data
    end

    private

    def fetch_rate_limit_data
      return @rate_limit_data if @rate_limit_data
      @rate_limit_data = client.fetch_rate_limit_data
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

# usage: Twitter::RateLimitChecker.new(user).call
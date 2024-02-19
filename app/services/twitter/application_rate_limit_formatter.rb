module Twitter
  class ApplicationRateLimitFormatter
    def self.call(rate_limits)
      new(rate_limits).call
    end

    def initialize(rate_limits)
      @rate_limits = rate_limits
    end

    def call
      exceeded_limits = []

      @rate_limits.each do |category, endpoints|
        endpoints.each do |endpoint, data|
          if data['remaining'] < data['limit']
            exceeded_limits << format_output(category, endpoint, data)
          end
        end
      end

      exceeded_limits
    end

    private

    def format_output(category, endpoint, data)
      "#{category} -> #{endpoint} | Limit: #{data['limit']} | Remaining: #{data['remaining']} | Reset: #{format_time(data['reset'])}"
    end

    def format_time(timestamp)
      Time.at(timestamp).strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end

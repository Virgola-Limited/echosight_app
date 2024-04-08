# lib/cron_expression_generator.rb

module CronExpressionGenerator
  def self.for_interval(interval)
    case interval
    when /m\z/
      minutes = interval.to_i
      "*/#{minutes} * * * *"
    when /h\z/
      hours = interval.to_i
      "0 */#{hours} * * *"
    else
      raise ArgumentError, "Unsupported interval format"
    end
  end
end

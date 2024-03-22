class NumberRoundingService
  def self.round_number(input)
    Rails.logger.debug('paul' + input.inspect)
    return input if input === false
    number = extract_number(input)
    sign = number.negative? ? '-' : ''
    number = number.round.abs

    rounded_number = if number < 999
                       number
                     elsif number < 1_000_000
                       "#{(number / 1_000.0).round}K"
                     else
                       "#{format('%.2f', number / 1_000_000.0)}M"
                     end

    format_output(sign, rounded_number, input)
  end

  private

  def self.extract_number(input)
    if input.is_a?(String) && input.include?('%')
      input.to_f
    else
      input
    end
  end

  def self.format_output(sign, rounded_number, original_input)
    if original_input.is_a?(String) && original_input.include?('%')
      "#{sign}#{rounded_number}% #{original_input.split.last}"
    else
      "#{sign}#{rounded_number}"
    end
  end
end
class NumberRoundingService
  def self.call(input)
    return input unless input && input.is_a?(Numeric)
    number = extract_number(input)
    sign = number.negative? ? '-' : ''
    number = number.abs

    rounded_number = if number < 999
                       number.round
                     elsif number < 1_000_000
                       format_thousands(number)
                     else
                       format_millions(number)
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

  def self.format_thousands(number)
    rounded = (number / 1000.0).round(1)
    remove_trailing_zeros("#{rounded}K")
  end

  def self.format_millions(number)
    rounded = (number / 1_000_000.0).round(2)
    remove_trailing_zeros("#{rounded}M")
  end

  def self.remove_trailing_zeros(number_string)
    number_string.sub(/\.0+([KM])$/, '\1')
  end

  def self.format_output(sign, rounded_number, original_input)
    if original_input.is_a?(String) && original_input.include?('%')
      "#{sign}#{rounded_number}% #{original_input.split.last}"
    else
      "#{sign}#{rounded_number}"
    end
  end
end
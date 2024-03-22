module Shared
  class MetricsCardComponent < ViewComponent::Base
    attr_reader :change_text

    def initialize(title:, count:, change:, tooltip_target:, change_text:, tooltip_text:, comparison_days: 7)
      @title = title
      @count = count
      @change = change
      @tooltip_target = tooltip_target
      @count = count
      @change_text = change_text || formatted_change
      @comparison_days = comparison_days
      @tooltip_text = tooltip_text
    end

    private

    def count_text
      return missing_data_message if @count == false
      @count.to_s
    end

    def formatted_change
      return missing_data_message if @change == false

      if @change > 0
        "#{@change}% increase"
      elsif @change < 0
        "#{@change.abs}% decrease"
      else
        'No change'
      end
    end

    def missing_data_message
      "Awaiting data..."
    end
  end
end

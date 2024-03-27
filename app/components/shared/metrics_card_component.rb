module Shared
  class MetricsCardComponent <  ApplicationComponent
    attr_reader :change_text

    def initialize(title:, count:, tooltip_target:, tooltip_text:, change_text: nil)
      @title = title
      @count = count
      @tooltip_target = tooltip_target
      @count = count
      @change_text = change_text || missing_data_message
      @tooltip_text = tooltip_text
    end

    private

    def count_text
      return missing_data_message if @count == false

      @count.to_s
    end

    def missing_data_message
      "Awaiting data..."
    end
  end
end

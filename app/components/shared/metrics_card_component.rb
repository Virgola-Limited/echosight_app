module Shared
  class MetricsCardComponent <  ApplicationComponent

    def initialize(title:, count:, tooltip_target:, tooltip_text:, change_text: nil)
      @title = title
      @count = count
      @tooltip_target = tooltip_target
      @change_text = change_text
      @tooltip_text = tooltip_text
    end

    private

    def change_text
      return missing_data_message(' change') if @change_text && !@change_text.empty?

      @change_text.to_s
    end

    def count_text
      return missing_data_message if @count == false|| @count.nil?

      @count.to_s
    end

    def missing_data_message(change_text = nil)
      "Awaiting#{change_text} data..."
    end
  end
end

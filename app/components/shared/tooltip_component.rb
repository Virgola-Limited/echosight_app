module Shared
  class TooltipComponent < ApplicationComponent
    def initialize(id:, text:, classes: nil)
      @id = id
      @text = text
      @classes = classes
    end

    def classes
      "#{@classes} inline-block absolute invisible z-10 py-2 px-3 text-sm font-medium text-white bg-gray-900 rounded-lg shadow-sm opacity-0 tooltip dark:bg-gray-700"
    end

    attr_reader :id
  end
end

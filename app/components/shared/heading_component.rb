module Shared
  class HeadingComponent < ApplicationComponent
    attr_reader :heading_type, :text

    def initialize(text: nil, heading_type:)
      @text = text
      @heading_type = heading_type
    end

    def classes
      case heading_type
      when :h1
        "text-5xl font-extrabold dark:text-white"
      when :h2
        "text-2xl sm:text-lg font-bold text-gray-900 dark:text-white"
      when :h3
        "text-1xl font-bold dark:text-white"
      when :h4
        "text-2xl font-bold dark:text-white"
      when :h5
        "text-xl font-bold dark:text-white"
      end
    end
  end
end

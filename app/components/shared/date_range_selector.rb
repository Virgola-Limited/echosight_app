module Shared
  class DateRangeSelector < ApplicationComponent
    attr_reader :page_user_handle, :date_range, :url_helper

    def initialize(page_user_handle: nil, date_range: '7d', url_helper: nil)
      @page_user_handle = page_user_handle
      @date_range = date_range
      @url_helper = url_helper
    end

    def selected_class(range)
      'bg-blue-600 text-white dark:bg-blue-600 dark:text-white' if date_range == range
    end

    def date_range_options
      Twitter::DateRangeOptions.all
    end
  end
end

module Shared
  class DateRangeSelector < ApplicationComponent
    attr_reader :page_user_handle, :date_range

    def initialize(page_user_handle:, date_range: '7d')
      @page_user_handle = page_user_handle
      @date_range = date_range
    end

    def selected_class(range)
      'bg-blue-600 text-white dark:bg-blue-600 dark:text-white' if date_range == range
    end
  end
end

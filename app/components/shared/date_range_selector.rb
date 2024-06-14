module Shared
  class DateRangeSelector < ApplicationComponent
    attr_reader :page_user_handle

    def initialize(page_user_handle:)
      @page_user_handle = page_user_handle
    end
  end
end

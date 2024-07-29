# frozen_string_literal: true

module Twitter
  module DateRangeHelper
    def parse_date_range(range)
      DateRangeOptions.parse_date_range(range)
    end

    def format_label(date, index)
      case date_range[:range]
      when '3m', '1y', 'all'
        date.day == 1 ? date.strftime('%b') : ''
      when '28d'
        index.even? ? date.strftime('%m/%d') : ''
      when '7d', '14d'
        date.strftime('%m/%d')
      else
        date.day == 1 ? date.strftime('%b %d') : date.strftime('%d')
      end
    end

    def maximum_days_of_data
      date_range[:start_time].to_date.upto(Date.current).count
    end
  end
end

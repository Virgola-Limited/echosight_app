# frozen_string_literal: true

module Twitter
  module DateRangeHelper
    def parse_date_range(range)
      end_time = Time.current.end_of_day
      start_time = case range
                   when '7d'
                     6.days.ago.beginning_of_day
                   when '14d'
                     13.days.ago.beginning_of_day
                   when '1m'
                     1.month.ago.beginning_of_day
                   when '3m'
                     3.months.ago.beginning_of_day
                   when '1y'
                     1.year.ago.beginning_of_day
                   else
                     6.days.ago.beginning_of_day
                   end
      { start_time: start_time, end_time: end_time, range: range }
    end

    def format_label(date, index)
      case date_range[:range]
      when '3m', '1y'
        date.day == 1 ? date.strftime('%b') : ''
      when '1m'
        index.even? ? date.strftime('%m/%d') : ''
      when '7d', '14d'
        date.strftime('%m/%d')
      else
        date.day == 1 ? date.strftime('%b %d') : date.strftime('%d')
      end
    end
  end
end


# frozen_string_literal: true
module Twitter
  module DateRangeOptions
    DATE_RANGES = [
      { value: '7d', label: '7 days' },
      { value: '14d', label: '14 days' },
      { value: '28d', label: '28 days' },
      { value: '3m', label: '3 months' },
      # { value: '1y', label: '1 year' },
      # { value: 'all', label: 'All time' }
    ].freeze

    def self.all
      DATE_RANGES
    end

    def self.parse_date_range(range)
      end_time = Time.current.end_of_day
      start_time = case range
                  when '7d'
                    6.days.ago.beginning_of_day
                  when '14d'
                    13.days.ago.beginning_of_day
                  when '28d'
                    27.days.ago.beginning_of_day
                  when '3m'
                    3.months.ago.beginning_of_day
                  when '1y'
                    1.year.ago.beginning_of_day
                  when 'all'
                    Time.at(0)
                  else
                    6.days.ago.beginning_of_day
                  end
      { start_time: start_time, end_time: end_time, range: range }
    end
  end
end

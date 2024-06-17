# frozen_string_literal: true

module Twitter
  class TwitterUserMetricsQuery
    attr_reader :identity, :date_range

    def initialize(identity:, date_range: '7d')
      @identity = identity
      @date_range = parse_date_range(date_range)
    end

    def followers_count
      current_period, past_period = time_periods[:current_period], time_periods[:past_period]
      return false unless current_period && past_period

      latest_follower_count = metrics.last&.followers_count
      followers_count_period_ago = metrics.find { |m| m.date == current_period.days.ago.to_date }&.followers_count

      return false unless followers_count_period_ago && latest_follower_count

      latest_follower_count - followers_count_period_ago
    end

    def followers_count_change_percentage
      current_period, past_period = time_periods[:current_period], time_periods[:past_period]
      return false unless current_period && past_period

      followers_count_past = metrics.find { |m| m.date == past_period.days.ago.to_date }&.followers_count
      followers_count_current = metrics.find { |m| m.date == current_period.days.ago.to_date }&.followers_count

      return false unless followers_count_past && followers_count_current

      calculate_percentage_change(followers_count_past, followers_count_current)
    end

    def followers_data_per_day
      start_time = date_range[:start_time]
      end_time = date_range[:end_time]

      user_metrics = TwitterUserMetric.where(identity_id: identity.id, date: start_time..end_time)
                                      .order(date: :asc)

      grouped_metrics = user_metrics.group_by { |metric| metric.date }

      (start_time.to_date..end_time.to_date).map.with_index do |date, index|
        daily_metric = grouped_metrics[date]&.first
        followers_count = daily_metric&.followers_count || 0

        formatted_label = format_label(date, index)

        { date: date, followers_count: followers_count, formatted_label: formatted_label }
      end
    end

    def followers_comparison_days
      time_periods[:current_period] || 0
    end

    private

    def metrics
      @metrics ||= TwitterUserMetric.where(identity_id: identity.id).order(date: :asc)
    end

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

    def calculate_percentage_change(old_value, new_value)
      return 0 if old_value == 0

      ((new_value - old_value) / old_value.to_f) * 100.0
    end

    def time_periods
      oldest_metric_date = metrics.first&.date
      return { current_period: nil, past_period: nil } unless oldest_metric_date

      days_since_oldest = (Date.current - oldest_metric_date.to_date).to_i
      @current_period, @past_period = calculate_dynamic_periods(days_since_oldest)
      { current_period: @current_period, past_period: @past_period }
    end

    def calculate_dynamic_periods(days)
      case days
      when 0..1
        [false, false]
      when 2..3
        [1, 2]
      when 4..5
        [2, 4]
      when 6..7
        [3, 6]
      when 8..9
        [4, 8]
      when 10..11
        [5, 10]
      when 12..13
        [6, 12]
      else
        [7, 14]
      end
    end
  end
end

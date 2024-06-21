# frozen_string_literal: true

module Twitter
  class TwitterUserMetricsQuery
    include DateRangeHelper

    attr_reader :identity, :date_range

    def initialize(identity:, date_range: '7d')
      @identity = identity
      @date_range = parse_date_range(date_range)
    end

    def followers_count
      return '' if insufficient_data?

      latest_follower_count = metrics.last&.followers_count
      followers_count_period_ago = metrics.find { |m| m.date == date_range[:start_time].to_date }&.followers_count

      return '' unless followers_count_period_ago && latest_follower_count

      latest_follower_count - followers_count_period_ago
    end

    def followers_count_change_percentage
      return '' if insufficient_data? || insufficient_data_for_comparison?

      followers_count_past = metrics.find { |m| m.date == (date_range[:start_time] - 7.days).to_date }&.followers_count
      followers_count_current = metrics.find { |m| m.date == date_range[:start_time].to_date }&.followers_count

      return '' unless followers_count_past && followers_count_current

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

        { date: date, data_points: followers_count, formatted_label: formatted_label }
      end
    end

    def followers_comparison_days
      (date_range[:start_time].to_date..date_range[:end_time].to_date).count
    end

    private

    def metrics
      @metrics ||= TwitterUserMetric.where(identity_id: identity.id).order(date: :asc)
    end

    def calculate_percentage_change(old_value, new_value)
      return 0 if old_value == 0

      ((new_value - old_value) / old_value.to_f) * 100.0
    end

    def insufficient_data?
      total_days_of_data < (Time.current.to_date - date_range[:start_time].to_date).to_i
    end

    def insufficient_data_for_comparison?
      total_days_of_data < (Time.current.to_date - date_range[:start_time].to_date).to_i * 2
    end

    def total_days_of_data
      first_metric = metrics.first
      return 0 unless first_metric

      (Time.current.to_date - first_metric.date).to_i + 1
    end
  end
end

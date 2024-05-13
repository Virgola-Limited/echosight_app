# frozen_string_literal: true

module Twitter
  class TwitterUserMetricsQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def followers_count
      current_period, past_period = time_periods[:current_period], time_periods[:past_period]
      return false unless current_period && past_period

      latest_follower_count = TwitterUserMetric.where(identity_id: user.identity.id)
                                               .order(date: :desc).first&.followers_count
      followers_count_period_ago = TwitterUserMetric.where(identity_id: user.identity.id, date: current_period.days.ago.to_date)
                                                    .last&.followers_count

      return false unless followers_count_period_ago && latest_follower_count

      latest_follower_count - followers_count_period_ago
    end

    def followers_count_change_percentage
      current_period, past_period = time_periods[:current_period], time_periods[:past_period]
      return false unless current_period && past_period

      followers_count_past = TwitterUserMetric.where(identity_id: user.identity.id, date: past_period.days.ago.to_date)
                                              .last&.followers_count
      followers_count_current = TwitterUserMetric.where(identity_id: user.identity.id, date: current_period.days.ago.to_date)
                                                 .first&.followers_count

      return false unless followers_count_past && followers_count_current

      calculate_percentage_change(followers_count_past, followers_count_current)
    end

    def followers_data_for_graph(number_of_days: 7)
      data = TwitterUserMetric.where(identity_id: @user.identity.id)
                                  .where('date >= ?', number_of_days.days.ago.to_date)
                                  .order(date: :asc)
                                  .pluck(:date, :followers_count)
      formatted_data, daily_data_points = format_for_graph(data)

      [formatted_data, daily_data_points]
    end

    def followers_comparison_days
      time_periods[:current_period] || 0
    end

    private

    def format_for_graph(data)
      formatted_data = daily_format(data)
      [formatted_data, data.map { |record| [record.first.strftime('%d %b'), record.last.to_i] }]
    end

    def daily_format(data)
      data.map { |record| record.first.strftime('%d %b') }
    end

    def calculate_percentage_change(old_value, new_value)
      return 0 if old_value == 0

      ((new_value - old_value) / old_value.to_f) * 100.0
    end

    def calculate_dynamic_periods(days)
      case days
      when 0..1
        [false, false]
      when 2..3
        [1, 2] # Use the most recent day and the second most recent day
      when 4..5
        [2, 4] # Use the most recent two days and the two days before those
      when 6..7
        [3, 6] # Use the most recent three days and the three days before those
      when 8..9
        [4, 8] # Use the most recent four days and the four days before those
      when 10..11
        [5, 10] # Use the most recent five days and the five days before those
      when 12..13
        [6, 12] # Use the most recent six days and the six days before those
      else
        [7, 14] # Defaults to last 7 days and the 7 days before that
      end
    end

    def time_periods
      oldest_metric_date = TwitterUserMetric.where(identity_id: user.identity.id).order(date: :asc).limit(1).first&.date
      return { current_period: nil, past_period: nil } unless oldest_metric_date

      days_since_oldest = (Date.current - oldest_metric_date.to_date).to_i
      @current_period, @past_period = calculate_dynamic_periods(days_since_oldest)
      { current_period: @current_period, past_period: @past_period }
    end
  end
end

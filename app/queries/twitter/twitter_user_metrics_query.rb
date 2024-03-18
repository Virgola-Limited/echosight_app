# frozen_string_literal: true

module Twitter
  class TwitterUserMetricsQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def followers_count
      # Fetch the followers count from 7 days ago and today
      followers_count_7_days_ago = TwitterUserMetric.where(identity_id: user.identity.id, date: 7.days.ago.to_date)&.last&.followers_count
      latest_follower_count = TwitterUserMetric.where(identity_id: user.identity.id).order(date: :desc)&.first&.followers_count

      return false unless followers_count_7_days_ago && latest_follower_count

      # Convert followers_count values to integers before subtraction
      latest_follower_count - followers_count_7_days_ago
    end

    def followers_count_change_percentage
      # Fetch the followers count for the last 14 days and 7 days ago
      followers_count_14_days_ago = TwitterUserMetric.where(identity_id: user.identity.id, date: 14.days.ago.to_date).last
      followers_count_7_days_ago = TwitterUserMetric.where(identity_id: user.identity.id, date: 7.days.ago.to_date).first

      return false unless followers_count_14_days_ago && followers_count_7_days_ago

      # Convert followers_count values to integers before calculation
      old_count = followers_count_14_days_ago.followers_count
      new_count = followers_count_7_days_ago.followers_count
      change_percentage = calculate_percentage_change(old_count, new_count)

      format_change_percentage(change_percentage)
    end

    def followers_data_for_graph
      data = TwitterUserMetric.where(identity_id: @user.identity.id)
                                  .where('date >= ?', 12.months.ago)
                                  .order(date: :asc)
                                  .pluck(:date, :followers_count)
      formatted_data, daily_data_points = format_for_graph(data)

      # Rails.logger.debug("Fetched Data: #{data.inspect}")
      # Rails.logger.debug("Formatted Labels: #{formatted_data.inspect}")
      # Rails.logger.debug("Daily Data Points: #{daily_data_points.inspect}")

      [formatted_data, daily_data_points]
    end

    def daily_followers_count(days_ago = 28)
      last_followers_count_per_day = TwitterUserMetric
                                       .where(identity_id: user.identity.id)
                                       .where('date >= ?', days_ago.days.ago)
                                       .select('DISTINCT ON (date) date, followers_count, created_at')
                                       .order('date, created_at DESC')
                                       .pluck(:date, :followers_count)

      daily_counts = {}
      last_followers_count_per_day.each_cons(2) do |previous_day, current_day|
        daily_increase = [current_day.second.to_i - previous_day.second.to_i, 0].max
        daily_counts[current_day.first] = daily_increase
      end

      daily_counts
    end

    private

    # TODO: This is currently broken for any other format except daily
    def format_for_graph(data)
      return daily_format(data)
      # formatted_data = case data.count
      #                  when 0..30
      #                    daily_format(data)
      #                  when 31..60
      #                    weekly_format(data)
      #                  else
      #                    monthly_format(data)
      #                  end
      # # Ensure daily data points are kept
      # [formatted_data, data.map { |record| [record.first.strftime('%d %b'), record.last.to_i] }]
    end

    def daily_format(data)
      data.map { |record| record.first.strftime('%d %b') }
    end

    def weekly_format(data)
      data.group_by { |record| record.first.to_date.cweek }
          .keys
          .map { |week| "Week #{week}" }
    end

    def monthly_format(data)
      data.group_by { |record| record.first.to_date.beginning_of_month }
          .keys
          .map { |month| month.strftime('%b %Y') }
    end

    def calculate_percentage_change(old_value, new_value)
      return 0 if old_value == 0
      ((new_value - old_value) / old_value.to_f) * 100.0
    end

    def format_change_percentage(change_percentage)
      if change_percentage.positive?
        "#{change_percentage.round(1)}% increase"
      elsif change_percentage.negative?
        "#{change_percentage.abs.round(1)}% decrease"
      else
        "No change"
      end
    end

  end
end

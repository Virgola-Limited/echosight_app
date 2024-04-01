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
      calculate_percentage_change(old_count, new_count)
    end

    def followers_data_for_graph(number_of_days: 7)
      data = TwitterUserMetric.where(identity_id: @user.identity.id)
                                  .where('date >= ?', number_of_days.days.ago.to_date)
                                  .order(date: :asc)
                                  .pluck(:date, :followers_count)
      formatted_data, daily_data_points = format_for_graph(data)

      [formatted_data, daily_data_points]
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
  end
end

# frozen_string_literal: true

module Twitter
  class FollowersQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def followers_count
      latest_follower_count = TwitterFollowersCount.where(identity_id: @user.identity.id)
                                                  .order(date: :desc)
                                                  .first
      return 0 unless latest_follower_count

      latest_follower_count.followers_count
    end

    def followers_count_change_percentage
      latest_follower_count = TwitterFollowersCount.where(identity_id: @user.identity.id)
                                                  .order(date: :desc)
                                                  .first
      previous_follower_count = TwitterFollowersCount.where(identity_id: @user.identity.id)
                                                    .where('date < ?', latest_follower_count&.date)
                                                    .order(date: :desc)
                                                    .first

      return false unless latest_follower_count && previous_follower_count

      change_percentage = calculate_percentage_change(previous_follower_count.followers_count.to_i, latest_follower_count.followers_count.to_i)
      format_change_percentage(change_percentage)
    end

    def followers_data_for_graph
      data = TwitterFollowersCount.where(identity_id: @user.identity.id)
                                  .where('date >= ?', 12.months.ago)
                                  .order(date: :asc)
                                  .pluck(:date, :followers_count)
      formatted_data, daily_data_points = format_for_graph(data)

      Rails.logger.debug("Fetched Data: #{data.inspect}")
      Rails.logger.debug("Formatted Labels: #{formatted_data.inspect}")
      Rails.logger.debug("Daily Data Points: #{daily_data_points.inspect}")

      [formatted_data, daily_data_points]
    end

    def daily_followers_count
      # Select the last record for each day based on the `created_at` timestamp
      last_followers_count_per_day = TwitterFollowersCount
                                       .where(identity_id: user.identity.id)
                                       .where('date >= ?', 30.days.ago)
                                       .select('DISTINCT ON (date) date, followers_count, created_at')
                                       .order('date, created_at DESC')
                                       .pluck(:date, :followers_count)

      # Calculate the daily follower count increase based on the last record for each day
      daily_counts = {}
      last_followers_count_per_day.each_cons(2) do |previous_day, current_day|
        # Ensure that we do not have negative values
        daily_increase = [current_day.second.to_i - previous_day.second.to_i, 0].max
        daily_counts[current_day.first] = daily_increase
      end

      daily_counts
    end

    private

    # TODO: This is currently broken for any other format except daily
    def format_for_graph(data)
      formatted_data = case data.count
                       when 0..30
                         daily_format(data)
                       when 31..60
                         weekly_format(data)
                       else
                         monthly_format(data)
                       end
      # Ensure daily data points are kept
      [formatted_data, data.map { |record| [record.first.strftime('%d %b'), record.last.to_i] }]
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

    # TODO: this need changing to not show decrease if its zero
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

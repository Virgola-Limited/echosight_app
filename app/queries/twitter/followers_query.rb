# frozen_string_literal: true

module Twitter
  class FollowersQuery
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def followers_count
      latest_follower_count = TwitterFollowerCount.where(identity_id: @user.identity.id)
                                                  .order(created_at: :desc)
                                                  .first
      raise 'No follower data available' unless latest_follower_count

      latest_follower_count.followers_count
    end

    def followers_count_change_percentage
      latest_follower_count = TwitterFollowerCount.where(identity_id: @user.identity.id)
                                                  .order(created_at: :desc)
                                                  .first
      previous_follower_count = TwitterFollowerCount.where(identity_id: @user.identity.id)
                                                    .where('created_at < ?', latest_follower_count.created_at)
                                                    .order(created_at: :desc)
                                                    .first

      return 'No sufficient data' unless latest_follower_count && previous_follower_count

      change_percentage = calculate_percentage_change(previous_follower_count.followers_count.to_i, latest_follower_count.followers_count.to_i)
      format_change_percentage(change_percentage)
    end

    def followers_data_for_graph
      data = TwitterFollowerCount.where(identity_id: @user.identity.id)
                                 .where('date >= ?', 12.months.ago)
                                 .order(date: :asc)
      format_for_graph(data)
    end

    private

    def format_for_graph(data)
      case data.count
      when 0
        raise 'No data available'
      when 1..30
        daily_format(data)
      when 31..60
        weekly_format(data)
      else
        monthly_format(data)
      end
    end

    def daily_format(data)
      data.map { |record| [record.date.strftime('%d %b'), record.followers_count.to_i] }
    end

    def weekly_format(data)
      data.group_by { |record| record.date.to_date.cweek }
          .map do |week, records|
            followers_sum = records.map { |r| r.followers_count.to_i }.sum
            ["Week #{week}", followers_sum]
          end
    end

    def monthly_format(data)
      data.group_by { |record| record.date.beginning_of_month }
          .map do |month, records|
            followers_sum = records.map { |r| r.followers_count.to_i }.sum
            [month.strftime('%b %Y'), followers_sum]
          end
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

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

    private

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

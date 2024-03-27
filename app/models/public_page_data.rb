class PublicPageData
    attr_accessor :engagement_rate_percentage_per_day, :first_day_impressions, :first_impressions_message,
                :follower_daily_data_points_for_graph, :follower_formatted_labels_for_graph, :followers_comparison_days,
                :followers_count, :followers_count_change_percentage_text, :impression_daily_data_points_for_graph,
                :impression_formatted_labels_for_graph, :impressions_change_since_last_week, :impressions_comparison_days,
                :impressions_count, :likes_change_since_last_week, :likes_comparison_days, :likes_count,
                :maximum_days_of_data, :top_posts, :days_of_data_in_recent_count, :days_of_data_in_difference_count, :tweet_count_over_available_time_period,
                :tweets_change_over_available_time_period, :user

    attr_writer :demo

    ROUNDABLE_METRICS = %i[
      impressions_count
      impressions_change_since_last_week
      likes_count
      followers_count
  ].freeze

  def initialize(attributes = {})
    @demo = false
    attributes.each do |name, value|
      public_send("#{name}=", value)
    end
  end

  ROUNDABLE_METRICS.each do |metric|
    define_method(metric) do
      rounded_value = instance_variable_get("@#{metric}")
      NumberRoundingService.call(rounded_value) if rounded_value
    end
  end

  def demo?
    @demo
  end

end

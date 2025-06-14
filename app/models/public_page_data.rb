class PublicPageData
  attr_accessor :days_of_data_in_difference_count,
                :days_of_data_in_recent_count,
                :engagement_rate_percentage_per_day,
                :followers_comparison_days,
                :followers_count,
                :followers_count_change_percentage_text,
                :followers_data_per_day,
                :impression_counts_per_day,
                :impressions_change_since_last_period,
                :impressions_comparison_days,
                :impressions_count,
                :last_cache_update,
                :likes_change_since_last_period,
                :likes_comparison_days,
                :likes_count,
                :maximum_days_of_data,
                :own_page,
                :top_posts,
                :tweet_count_over_available_time_period,
                :tweets_change_over_available_time_period,
                :user

  attr_reader :date_range
  attr_writer :demo

  ROUNDABLE_METRICS = %i[
    impressions_count
    impressions_change_since_last_period
    likes_count
    followers_count
  ].freeze

  def initialize(attributes = {})
    @demo = false
    attributes.each do |name, value|
      public_send("#{name}=", value)
    end
  end

  def date_range=(value)
    @date_range = sanitize_date_range(value)
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

  private

  def sanitize_date_range(range)
    valid_ranges = Twitter::DateRangeOptions.all.map { |r| r[:value] }
    valid_ranges.include?(range) ? range : '7d'
  end
end
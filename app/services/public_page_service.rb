class PublicPageService < Services::Base
  include Rails.application.routes.url_helpers
  include Cacheable

  attr_reader :current_admin_user, :current_user, :user, :handle

  def initialize(handle:, current_user: nil, current_admin_user: nil)
    @handle = handle
    @current_user = current_user
    identity = Identity.find_by(handle: handle)
    @user = identity.user if identity.present?
    @current_admin_user = current_admin_user
  end

  def call
    if @user.nil?
      if handle == 'demo' && !current_user.guest?
        @user = current_user
      end
    end
    result = determine_public_page_status
    case result.status
    when :demo
      DemoPublicPageService.call(user: user)
    when :success
      public_page_data
    end
  end

  # Move struct
  Result = Struct.new(:status, :message, :redirect_path, keyword_init: true)

  def show_public_page_demo?
    user&.identity.nil? || not_enough_data?
  end

  # Crap ChatGTP code fix later no need for result object
  def determine_public_page_status
    if show_public_page_demo?
      Result.new(status: :demo)
    else
      Result.new(status: :success)
    end
  end

  private

  def not_enough_data?
    UserTwitterDataUpdate.recent_data(user.identity).count < 2
  end

  def public_page_data
    cache_key = cache_key_for_user(user)

    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      # The block to generate data if cache miss occurs
      generate_public_page_data
    end
  end

  private

  def generate_public_page_data
    @public_page_data ||= PublicPageData.new(
      engagement_rate_percentage_per_day: engagement_rate_percentage_per_day,
      first_day_impressions: first_day_impressions,
      first_impressions_message: first_impressions_message,
      follower_daily_data_points_for_graph: follower_daily_data_points_for_graph,
      follower_formatted_labels_for_graph: follower_formatted_labels_for_graph,
      followers_comparison_days: followers_comparison_days,
      followers_count: followers_count,
      followers_count_change_percentage_text: followers_count_change_percentage_text,
      impression_daily_data_points_for_graph: impression_daily_data_points_for_graph,
      impression_formatted_labels_for_graph: impression_formatted_labels_for_graph,
      impressions_change_since_last_week: impressions_change_since_last_week,
      impressions_comparison_days: impressions_comparison_days,
      impressions_count: impressions_count,
      likes_change_since_last_week: likes_change_since_last_week,
      likes_comparison_days: likes_comparison_days,
      likes_count: likes_count,
      maximum_days_of_data: maximum_days_of_data,
      top_posts: top_posts,
      days_of_data_in_recent_count: days_of_data_in_recent_count,
      days_of_data_in_difference_count: days_of_data_in_difference_count,
      tweet_count_over_available_time_period: tweet_count_over_available_time_period,
      tweets_change_over_available_time_period: tweets_change_over_available_time_period,
      user: user
    )
  end

  def engagement_rates_empty_or_zero?
    engagement_rate_percentages = public_page_data_attributes.select { |attr| attr.is_a?(Array) }
    engagement_rate_percentages.any? do |array|
      array.empty? || array.any? do |element|
        element.is_a?(Hash) && element[:engagement_rate_percentage].to_f.zero?
      end
    end
  end

  def public_page_data_attributes
    [
      public_page_data.engagement_rate_percentage_per_day,
      public_page_data.follower_daily_data_points_for_graph,
      public_page_data.impression_daily_data_points_for_graph,
      public_page_data.followers_count,
      public_page_data.impressions_count,
      public_page_data.likes_count,
      public_page_data.top_posts,
      public_page_data.tweet_count_over_available_time_period
    ]
  end

  def maximum_days_of_data
    @maximum_days_of_data ||= tweet_metrics_query.maximum_days_of_data
  end

  def tweet_count_over_available_time_period
    @tweet_count_over_available_time_period ||= post_counts_query.tweet_count_over_available_time_period
  end

  def tweets_change_over_available_time_period
    @tweets_change_over_available_time_period ||= post_counts_query.tweets_change_over_available_time_period
  end

  def days_of_data_in_recent_count
    @days_of_data_in_recent_count ||= post_counts_query.days_of_data_in_recent_count
  end

  def days_of_data_in_difference_count
    @days_of_data_in_difference_count ||= post_counts_query.days_of_data_in_difference_count
  end

  # dry up
  def format_impressions_change(change)
    return change unless change
    return 'No change' if change.nil? || change.zero?

    format = change.positive? ? '%d%% increase' : '%d%% decrease'
    format % change.abs
  end

  def format_likes_change(change)
    return change unless change
    return 'No change' if change.nil? || change.zero?

    format = change.positive? ? '%d%% increase' : '%d%% decrease'
    format % change.abs
  end

  def format_change_percentage(change_percentage)
    return change_percentage unless change_percentage

    if change_percentage.positive?
      "#{change_percentage.round(1)}% increase"
    elsif change_percentage.negative?
      "#{change_percentage.abs.round(1)}% decrease"
    else
      "No change"
    end
  end

  def impressions_count
    @impressions_count ||= tweet_metrics_query.impressions_count
  end

  def impressions_change_since_last_week
    @impressions_change_since_last_week ||= format_impressions_change(tweet_metrics_query.impressions_change_since_last_week)
  end

  def impressions_comparison_days
    @impressions_comparison_days ||= 7  # This is set to a static value but can be made dynamic as needed.
  end


  def likes_count
    @likes_count ||= tweet_metrics_query.likes_count
  end

  def likes_change_since_last_week
    @likes_change_since_last_week ||= format_likes_change(tweet_metrics_query.likes_change_since_last_week)
  end

  def likes_comparison_days
    @likes_comparison_days ||= 7  # This can be adjusted to be dynamic if necessary.
  end


  def followers_count
    @followers_count ||= twitter_user_metrics_query.followers_count
  end

  def followers_count_change_percentage_text
    @followers_count_change_percentage_text ||= format_change_percentage(twitter_user_metrics_query.followers_count_change_percentage)
  end

  def followers_comparison_days
    @followers_comparison_days ||= dynamic_followers_comparison_days
  end

  def follower_formatted_labels_for_graph
    @follower_formatted_labels_for_graph ||= followers_data_for_graph.first
  end

  def follower_daily_data_points_for_graph
    @follower_daily_data_points_for_graph ||= followers_data_for_graph.last
  end

  # Helper method to encapsulate fetching both formatted follower data and daily data points in one call to minimize database queries.
  def followers_data_for_graph
    @followers_data_for_graph ||= twitter_user_metrics_query.followers_data_for_graph
  end

  def dynamic_followers_comparison_days
    7
  end

  def engagement_rate_percentage_per_day
    @engagement_rate_percentage_per_day ||= tweet_metrics_query.engagement_rate_percentage_per_day
  end

  def impression_daily_data_points_for_graph
    @impression_daily_data_points_for_graph ||= tweet_metrics_query.impression_counts_per_day.map do |data|
      data[:impression_count] >= 0 ? data[:impression_count] : 0
    end
  end

  def impression_formatted_labels_for_graph
    @impression_formatted_labels_for_graph ||= tweet_metrics_query.impression_counts_per_day.map do |data|
      format_label_with_impression_count(data)
    end
  end

  def first_impressions_message
    @first_impressions_message ||= begin
      if first_day_impressions
        "Based on #{first_day_impressions[:impression_count].to_s} on #{first_day_impressions[:date].to_s} "
      else
        ''
      end
    end
  end

  def first_day_impressions
    @first_day_impressions ||= current_admin_user ? tweet_metrics_query.first_day_impressions : nil
  end

  def format_label_with_impression_count(data)
    label = data[:date].strftime('%b %d')
    label += " (#{data[:impression_count]})" if current_admin_user.present?
    label
  end

  def top_posts
    @top_posts ||= tweet_metrics_query.top_tweets_for_user
  end

  def profile_conversion_rate_query
    Twitter::ProfileConversionRateQuery.new
  end

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(user: user)
  end

  def twitter_user_metrics_query
    Twitter::TwitterUserMetricsQuery.new(user)
  end

  def post_counts_query
    Twitter::PostCountsQuery.new(user: user)
  end
end

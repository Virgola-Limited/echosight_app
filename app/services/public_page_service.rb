# frozen_string_literal: true

class PublicPageService < Services::Base
  include Rails.application.routes.url_helpers
  include Cacheable

  attr_reader :current_admin_user, :current_user, :identity, :handle, :date_range

  def initialize(handle:, current_user: nil, current_admin_user: nil, date_range: nil)
    @handle = handle
    @current_user = current_user
    @identity = Identity.find_by_handle(handle)
    @current_admin_user = current_admin_user
    @date_range = date_range || '7d'
  end

  def call
    result = determine_public_page_status
    case result.status
    when :demo
      DemoPublicPageService.call
    when :success
      public_page_data
    end
  end

  # Move struct
  Result = Struct.new(:status, :message, :redirect_path, keyword_init: true)

  def show_public_page_demo?
    return true if identity.nil?

    identity.nil?
  end

  # Crap ChatGTP code fix later no need for result object
  def determine_public_page_status
    if show_public_page_demo?
      Result.new(status: :demo)
    else
      Result.new(status: :success)
    end
  end

  def user
    # This code is a bit wierd as its used in public_page_data
    # and the user.id is sometimes identity.id.
    # worth changing to just use identity
    @page_user = identity.user if identity.present?
    if @page_user.nil?
      @page_user = current_user if (handle == 'demo' && !current_user.guest?)
    end
    @page_user ||= UnclaimedUser.new(identity: identity)
    @page_user
  end

  def generate_public_page_data
    @generate_public_page_data ||= PublicPageData.new(
      engagement_rate_percentage_per_day:,
      followers_data_per_day:,
      followers_comparison_days:,
      followers_count:,
      followers_count_change_percentage_text:,
      impression_counts_per_day:,
      impressions_change_since_last_week:,
      impressions_comparison_days:,
      impressions_count:,
      likes_change_since_last_week:,
      likes_comparison_days:,
      likes_count:,
      maximum_days_of_data:,
      top_posts:,
      days_of_data_in_recent_count:,
      days_of_data_in_difference_count:,
      tweet_count_over_available_time_period:,
      tweets_change_over_available_time_period:,
      user: user,
      last_cache_update: @last_cache_update,
      date_range: date_range
    )
  end

  private

  def public_page_data
    cache_key = cache_key_for_user_public_page(user, date_range: date_range)

    data = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      @last_cache_update = Time.current
      generate_public_page_data
    end

    unless @last_cache_update
      # If cache was hit, fetch the last update time from cache metadata
      @last_cache_update = Rails.cache.read("#{cache_key}/updated_at")
    end

    Rails.cache.write("#{cache_key}/updated_at", @last_cache_update)

    data.last_cache_update = @last_cache_update if data.respond_to?(:last_cache_update=)

    data
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

  def format_percentage_change(change_percentage)
    return change_percentage unless change_percentage && change_percentage.is_a?(Numeric)

    if change_percentage.positive?
      "#{change_percentage.round(1)}% increase"
    elsif change_percentage.negative?
      "#{change_percentage.abs.round(1)}% decrease"
    else
      'No change'
    end
  end

  def impressions_count
    @impressions_count ||= impressions_query.impressions_count
  end

  def impressions_change_since_last_week
    @impressions_change_since_last_week ||= format_percentage_change(impressions_query.impressions_change_since_last_week)
  end

  def impressions_comparison_days
    @impressions_comparison_days ||= 7 # This is set to a static value but can be made dynamic as needed.
  end

  def likes_count
    @likes_count ||= tweet_metrics_query.likes_count
  end

  def likes_change_since_last_week
    @likes_change_since_last_week ||= format_percentage_change(tweet_metrics_query.likes_change_since_last_week)
  end

  def likes_comparison_days
    @likes_comparison_days ||= 7 # This can be adjusted to be dynamic if necessary.
  end

  def followers_count
    @followers_count ||= twitter_user_metrics_query.followers_count
  end

  def followers_count_change_percentage_text
    @followers_count_change_percentage_text ||= format_percentage_change(twitter_user_metrics_query.followers_count_change_percentage)
  end

  def followers_comparison_days
    @followers_comparison_days ||= twitter_user_metrics_query.followers_comparison_days
  end

  # Helper method to encapsulate fetching both formatted follower data and daily data points in one call to minimize database queries.
  def followers_data_per_day
    @followers_data_per_day ||= twitter_user_metrics_query.followers_data_per_day
  end

  def engagement_rate_percentage_per_day
    @engagement_rate_percentage_per_day ||= engagement_rate_query.engagement_rate_percentage_per_day
  end

  def impression_counts_per_day
    @impression_counts_per_day ||= impressions_query.impression_counts_per_day
  end

  def top_posts
    @top_posts ||= tweet_metrics_query.top_tweets_for_user
  end

  def engagement_rate_query
    Twitter::TweetMetrics::EngagementRateQuery.new(identity:, date_range:)
  end

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(identity:, date_range:)
  end

  def impressions_query
    Twitter::TweetMetrics::ImpressionsQuery.new(identity:, date_range:)
  end

  def twitter_user_metrics_query
    Twitter::TwitterUserMetricsQuery.new(identity:, date_range:)
  end

  def post_counts_query
    Twitter::PostCountsQuery.new(identity:, date_range:)
  end
end

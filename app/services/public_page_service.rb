class PublicPageService < Services::Base
  attr_reader :user, :current_admin_user
  def initialize(user:, current_admin_user:)
    @user = user
    @current_admin_user = current_admin_user
  end

  def call
    @maximum_days_of_data = Twitter::TweetMetricsQuery.maximum_days_of_data
    store_post_counts
    store_impression_counts
    store_likes_counts
    store_follower_counts

    store_followers_graph_data
    store_engagement_rate_graph_data
    store_impressions_graph_data
    store_top_posts

    results
  end

  private

  def store_post_counts
    @tweet_count_over_available_time_period = tweet_metrics_query.tweet_count_over_available_time_period
    @tweets_change_over_available_time_period = tweet_metrics_query.tweets_change_over_available_time_period
    @tweet_comparison_days = tweet_metrics_query.tweet_comparison_days
    if @tweets_change_over_available_time_period > 0
      @tweets_change_over_available_time_period = "#{@tweets_change_over_available_time_period} increase"
    elsif @tweets_change_over_available_time_period < 0
      @tweets_change_over_available_time_period = "#{@tweets_change_over_available_time_period.abs} decrease"
    else
      @tweets_change_over_available_time_period = 'No change'
    end
    [@tweet_count_over_available_time_period, @tweets_change_over_available_time_period, @tweet_comparison_days]
  end

  def store_impression_counts
    @impressions_count = tweet_metrics_query.impressions_count
    @impressions_change_since_last_week = tweet_metrics_query.impressions_change_since_last_week
    if @impressions_change_since_last_week
      NumberRoundingService.round_number(@impressions_change_since_last_week)
      if @impressions_change_since_last_week > 0
        @impressions_change_since_last_week = "#{@impressions_change_since_last_week}% increase"
      elsif @impressions_change_since_last_week < 0
        @impressions_change_since_last_week = "#{@impressions_change_since_last_week.abs}% decrease"
      else
        @impressions_change_since_last_week = 'No change'
      end
    end

    # this needs to change to be dynamic
    @impressions_comparison_days = 7
  end

  def store_likes_counts
    @likes_count = tweet_metrics_query.likes_count
    @likes_change_since_last_week = tweet_metrics_query.likes_change_since_last_week
    if @likes_change_since_last_week
      NumberRoundingService.round_number(@likes_change_since_last_week)
      if @likes_change_since_last_week > 0
        @likes_change_since_last_week = "#{@likes_change_since_last_week}% increase"
      elsif @likes_change_since_last_week < 0
        @likes_change_since_last_week = "#{@likes_change_since_last_week.abs}% decrease"
      else
        @likes_change_since_last_week = 'No change'
      end
    end

    @likes_comparison_days = 7
  end

  def  store_follower_counts
    @followers_count = followers_query.followers_count
    @followers_count_change_percentage_text = format_change_percentage(followers_query.followers_count_change_percentage)

    # this needs to change to be dynamic
    @followers_comparison_days = 7
  end

  def store_followers_graph_data
    formatted_follower_data, follower_daily_data_points = followers_query.followers_data_for_graph
    @follower_formatted_labels_for_graph = formatted_follower_data
    @follower_daily_data_points_for_graph = follower_daily_data_points
  end

  def store_engagement_rate_graph_data
    @engagement_rate_percentage_per_day = tweet_metrics_query.engagement_rate_percentage_per_day
  end

  def store_impressions_graph_data
    impression_counts_per_day = tweet_metrics_query.impression_counts_per_day
    if current_admin_user
      @first_day_impressions = tweet_metrics_query.first_day_impressions
      @first_impressions_message = ''
      if @first_day_impressions
        @first_impressions_message = "Based on #{@first_day_impressions[:impression_count].to_s} on #{@first_day_impressions[:date].to_s} "
      end
    end

    @impression_formatted_labels_for_graph = tweet_metrics_query.impression_counts_per_day.map do |data|
      label = data[:date].strftime('%b %d')
      label += " (#{data[:impression_count]})" if current_admin_user.present?
      label
    end

    @impression_daily_data_points_for_graph = tweet_metrics_query.impression_counts_per_day.map do |data|
      data[:impression_count] >= 0 ? data[:impression_count] : 0
    end
  end

  def store_top_posts
    @top_posts = tweet_metrics_query.top_tweets_for_user
  end

  PublicPageResults = Struct.new(
    :engagement_rate_percentage_per_day,
    :first_day_impressions,
    :first_impressions_message,
    :follower_daily_data_points_for_graph,
    :follower_formatted_labels_for_graph,
    :followers_comparison_days,
    :followers_count,
    :followers_count_change_percentage_text,
    :impression_daily_data_points_for_graph,
    :impression_formatted_labels_for_graph,
    :impressions_change_since_last_week,
    :impressions_comparison_days,
    :impressions_count,
    :likes_change_since_last_week,
    :likes_comparison_days,
    :likes_count,
    :maximum_days_of_data,
    :top_posts,
    :tweet_comparison_days,
    :tweet_count_over_available_time_period,
    :tweets_change_over_available_time_period
  )

  ROUNDABLE_METRICS = %i[
    impressions_count
    impressions_change_since_last_week
    likes_count
    followers_count
].freeze

  def results

    ROUNDABLE_METRICS.each do |metric|
      instance_variable_set("@#{metric}", number_rounding_service.round_number(instance_variable_get("@#{metric}")))
    end
    blah = PublicPageResults.new(
      @engagement_rate_percentage_per_day,
      @first_day_impressions,
      @first_impressions_message,
      @follower_daily_data_points_for_graph,
      @follower_formatted_labels_for_graph,
      @followers_comparison_days,
      @followers_count,
      @followers_count_change_percentage_text,
      @impression_daily_data_points_for_graph,
      @impression_formatted_labels_for_graph,
      @impressions_change_since_last_week,
      @impressions_comparison_days,
      @impressions_count,
      @likes_change_since_last_week,
      @likes_comparison_days,
      @likes_count,
      @maximum_days_of_data,
      @top_posts,
      @tweet_comparison_days,
      @tweet_count_over_available_time_period,
      @tweets_change_over_available_time_period
    )
    Rails.logger.debug('paul' + blah.inspect)
    blah
  end

  def profile_conversion_rate_query
    Twitter::ProfileConversionRateQuery.new
  end

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(user: user)
  end

  def followers_query
    Twitter::TwitterUserMetricsQuery.new(user)
  end

  def number_rounding_service
    NumberRoundingService
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
end

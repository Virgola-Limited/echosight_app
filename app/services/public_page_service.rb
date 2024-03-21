class PublicPageService < Services::Base
  attr_reader :user, :current_admin_user
  def initialize(user:, current_admin_user:)
    @user = user
    @current_admin_user = current_admin_user
  end

  def call
    @maximum_days_of_data = Twitter::TweetMetricsQuery.maximum_days_of_data

    ############################
    # Posts/Tweet Counts
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

    ############################
    # Impressions
    @impressions_count = tweet_metrics_query.impressions_count
    @impressions_change_since_last_week = tweet_metrics_query.impressions_change_since_last_week
    if @impressions_change_since_last_week
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

    ############################
    # Likes Counts
    @likes_count = tweet_metrics_query.likes_count
    @likes_change_since_last_week = tweet_metrics_query.likes_change_since_last_week
    if @likes_change_since_last_week
      if @likes_change_since_last_week > 0
        @likes_change_since_last_week = "#{@likes_change_since_last_week}% increase"
      elsif @likes_change_since_last_week < 0
        @likes_change_since_last_week = "#{@likes_change_since_last_week.abs}% decrease"
      else
        @likes_change_since_last_week = 'No change'
      end
    end

    @likes_comparison_days = 7

    ############################
    # Followers Counts
    @followers_count = followers_query.followers_count
    @followers_count_change_percentage_text = followers_query.followers_count_change_percentage


    # this needs to change to be dynamic
    @followers_comparison_days = 7

    ############################
    # Followers Graph
    formatted_follower_data, follower_daily_data_points = followers_query.followers_data_for_graph
    @follower_formatted_labels_for_graph = formatted_follower_data
    @follower_daily_data_points_for_graph = follower_daily_data_points

    ############################
    # Engagement Graph
    @engagement_rate_percentage_per_day = tweet_metrics_query.engagement_rate_percentage_per_day

    ############################
    # Impressions over Time Graph
    impression_counts_per_day = tweet_metrics_query.impression_counts_per_day
    # Admin only data
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
    # Rails.logger.debug('paul' + @impression_daily_data_points_for_graph.inspect)

    ############################
    # Profile Conversion Rate
    # @profile_clicks_data = tweet_metrics_query.profile_clicks_count_per_day
    # @followers_data = followers_query.daily_followers_count
    # @conversion_rates_data_for_graph = profile_conversion_rate_query.conversion_rates_data_for_graph(profile_clicks_data: @profile_clicks_data, followers_data: @followers_data)

    ############################
    # Top Posts / Tweets
    @top_posts = tweet_metrics_query.top_tweets_for_user

    ############################

    results
  end

  PublicPageResults = Struct.new(
    :maximum_days_of_data,
    :tweet_count_over_available_time_period,
    :tweets_change_over_available_time_period,
    :tweet_comparison_days,
    :impressions_count,
    :impressions_change_since_last_week,
    :impressions_comparison_days,
    :likes_count,
    :likes_change_since_last_week,
    :likes_comparison_days,
    :followers_count,
    :followers_change_since_last_week,
    :followers_comparison_days,
    :follower_formatted_labels_for_graph,
    :follower_daily_data_points_for_graph,
    :followers_count_change_percentage_text,
    :engagement_rate_percentage_per_day,
    :impression_formatted_labels_for_graph,
    :impression_daily_data_points_for_graph,
    :top_posts,
    :first_day_impressions,
    :first_impressions_message
  )

  def results
    PublicPageResults.new(
      @maximum_days_of_data,
      @tweet_count_over_available_time_period,
      @tweets_change_over_available_time_period,
      @tweet_comparison_days,
      @impressions_count,
      @impressions_change_since_last_week,
      @impressions_comparison_days,
      @likes_count,
      @likes_change_since_last_week,
      @likes_comparison_days,
      @followers_count,
      @followers_change_since_last_week,
      @followers_comparison_days,
      @follower_formatted_labels_for_graph,
      @follower_daily_data_points_for_graph,
      @followers_count_change_percentage_text,
      @engagement_rate_percentage_per_day,
      @impression_formatted_labels_for_graph,
      @impression_daily_data_points_for_graph,
      @top_posts,
      @first_day_impressions,
      @first_impressions_message
    )
  end

  private

  def profile_conversion_rate_query
    Twitter::ProfileConversionRateQuery.new
  end

  def tweet_metrics_query
    Twitter::TweetMetricsQuery.new(user: user)
  end

  def followers_query
    Twitter::TwitterUserMetricsQuery.new(user)
  end
end
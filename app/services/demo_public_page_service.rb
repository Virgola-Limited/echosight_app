class DemoPublicPageService < Services::Base
  attr_reader :user
  def initialize(user:)
    @user = user
  end

  def call
    follower_info = generate_follower_info
    impression_info = generate_impression_info

    PublicPageData.new(
      engagement_rate_percentage_per_day: generate_engagement_data,
      first_day_impressions: generate_first_day_impressions,
      first_impressions_message: "Based on #{generate_first_day_impressions[:impression_count]} on #{generate_first_day_impressions[:date]}",
      follower_daily_data_points_for_graph: follower_info[:data_points], # Use data points from the refactored method
      follower_formatted_labels_for_graph: follower_info[:labels], # Use labels from the refactored method

      followers_comparison_days: 7,
      followers_count: 43,
      followers_count_change_percentage_text: "0.5% increase",
      impression_daily_data_points_for_graph: impression_info[:data_points], # Use data points from the refactored method
      impression_formatted_labels_for_graph: impression_info[:labels], # Use labels from the refactored method
      impressions_change_since_last_week: "74.52% decrease",
      impressions_comparison_days: 7,
      impressions_count: -5817920,
      likes_change_since_last_week: "9.72% decrease",
      likes_comparison_days: 7,
      likes_count: -2913,
      maximum_days_of_data: 7,
      top_posts: generate_top_posts,
      tweet_comparison_days: 3,
      tweet_count_over_available_time_period: 20,
      tweets_change_over_available_time_period: "231 decrease",
      user: user,
      demo: true
    )
  end

  private

  def generate_engagement_data
    (0..6).map do |i|
      # Assuming you have a way to calculate or retrieve the engagement rate for each day
      engagement_rate = calculate_engagement_rate_for_day(Date.today - i)
      { date: Date.today - i, engagement_rate_percentage: engagement_rate }
    end.reverse
  end

  def calculate_engagement_rate_for_day(date)
    2.51 - (date.wday * 0.1)
  end

  def generate_first_day_impressions
    { date: Date.today - 6, impression_count: 332539 }
  end

  def generate_follower_info
    follower_counts = [6719, 6738, 6756, 6759, 6762] # Example follower counts for the last 5 days

    # Extend the array to accommodate 7 days, assuming the last known value for missing days
    follower_counts.fill(follower_counts.last, follower_counts.length...7)

    data_points = []
    labels = []

    follower_counts.each_with_index do |count, i|
      date_label = (Date.today - (follower_counts.length - 1) + i).strftime("%d %b")
      data_points << [date_label, count]
      labels << date_label
    end

    { data_points: data_points, labels: labels }
  end

  def generate_impression_info
    # Example impression counts for a predefined number of days
    impression_counts = [2149, 51817, 72352, 29071, 15000, 8000, 12345]

    data_points = []
    labels = []

    impression_counts.each_with_index do |count, i|
      date_label = (Date.today - (impression_counts.length - 1) + i).strftime("%b %d")
      data_points << count
      labels << "#{date_label} (#{count})"
    end

    { data_points: data_points, labels: labels }
  end

  def generate_top_posts
    (0..4).map do |i|
      # Simulate a Tweet object with necessary attributes
      tweet = OpenStruct.new(
        text: "Demo tweet text #{i + 1}",
        twitter_id: i + 1000, # Simulate a Twitter ID
        id: i + 100 # Simulate a Tweet ID
      )

      # Simulate a TweetMetric object with necessary attributes and an associated Tweet object
      OpenStruct.new(
        tweet: tweet,
        retweet_count: [7, 1, 3, 1, 1][i],
        like_count: [178, 9, 95, 93, 101][i],
        quote_count: [11, 5, 12, 0, 3][i],
        impression_count: [34345, 32035, 30004, 18220, 17522][i],
        reply_count: [150, 4, 96, 2, 77][i],
        bookmark_count: [5, 0, 2, 0, 10][i],
        engagement_rate_percentage: calculate_engagement_rate([7, 1, 3, 1, 1][i], [178, 9, 95, 93, 101][i], [11, 5, 12, 0, 3][i], [150, 4, 96, 2, 77][i], [5, 0, 2, 0, 10][i], [34345, 32035, 30004, 18220, 17522][i]),
        pulled_at: Date.today - i
      )
    end.sort_by { |post| -post.engagement_rate_percentage }
  end

  def calculate_engagement_rate(retweet_count, like_count, quote_count, reply_count, bookmark_count, impression_count)
    ((retweet_count + like_count + quote_count + reply_count + bookmark_count).to_f / impression_count * 100).round(2)
  end

end

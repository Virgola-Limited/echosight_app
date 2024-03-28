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
      days_of_data_in_recent_count: 3,
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
    custom_tweets = [
      { id: 101, twitter_id: 1772826047878516856, text: "Just asked my smart fridge for the weather forecast, and it advised me to chill. Tech humor never gets old!" },
      { id: 102, twitter_id: 1772826156355764407, text: "If you think a minute goes by really fast, you've never waited for your code to compile." },
      { id: 103, twitter_id: 1754363215839142327, text: "Have you been introduced to the BOFH before?" },
      { id: 104, twitter_id: 1772835317466407361, text: "In a relationship with my Wi-Fi. It's getting serious and we just shared our first password." },
      { id: 105, twitter_id: 1772829628991946912, text: "I learnt more on the job in six months with a supportive team than I ever did at school." },
      { id: 106, twitter_id: 1727444841683202207, text: "I don't like working in fields where I can't stand out. Music production became too accessible and what I did was no longer special so I moved to something harder where my efforts could be noticed." },
      { id: 107, twitter_id: 1772787456544592133, text: "TIL Why does Cloudflare use lava lamps to help with encryption?" },
      { id: 108, twitter_id: 1772778052667470267, text: "I'm getting some mad ChatGPT nostalgia where it just cuts out before finishing stuff and doesn't give you the rest of the answer. How is AI a threat to anyone?" },
      { id: 109, twitter_id: 1772574111882961249, text: "What do you think the next leap in machine learning and LLMs is going to be like?" },
      { id: 110, twitter_id: 1772837100993569080, text: "Just overheard two algorithms discussing privacy. They didn't say much. I guess they prefer to keep things encrypted." }
    ]

    custom_tweets.map do |tweet|
      OpenStruct.new(
        id: tweet[:id],
        twitter_id: tweet[:twitter_id],
        text: tweet[:text]
      )
    end

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

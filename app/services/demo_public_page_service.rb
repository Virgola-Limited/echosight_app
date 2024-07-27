class DemoPublicPageService < Services::Base

  FOLLOWERS_DATA = {
    counts: [6719, 6938, 7156, 7159, 7762, 7762, 7762],
    comparison_days: 7,
    count: 43,
    count_change_percentage_text: "0.5% increase"
  }.freeze

  IMPRESSIONS_DATA = {
    counts: [12149, 51817, 72352, 29071, 15000, 18000, 12345],
    change_since_last_week: "74.52% increase",
    comparison_days: 7,
    count: 5817920
  }.freeze

  LIKES_DATA = {
    change_since_last_week: "9.72% increase",
    comparison_days: 7,
    count: 2913
  }.freeze

  CUSTOM_TWEETS = [
    {
      id: 1772826047878516856,
      text: "Just asked my smart fridge for the weather forecast, and it advised me to chill. Tech humor never gets old!",
      retweet_count: 95,
      like_count: 242,
      quote_count: 13,
      impression_count: 45560,
      reply_count: 37,
      bookmark_count: 29
    },
    {
      id: 1772826156355764407,
      text: "If you think a minute goes by really fast, you've never waited for your code to compile.",
      retweet_count: 112,
      like_count: 318,
      quote_count: 21,
      impression_count: 50789,
      reply_count: 45,
      bookmark_count: 34
    },
    {
      id: 1754363215839142327,
      text: "Have you been introduced to the BOFH before?",
      retweet_count: 58,
      like_count: 139,
      quote_count: 9,
      impression_count: 32045,
      reply_count: 20,
      bookmark_count: 15
    },
    {
      id: 1772835317466407361,
      text: "In a relationship with my Wi-Fi. It's getting serious and we just shared our first password.",
      retweet_count: 76,
      like_count: 265,
      quote_count: 18,
      impression_count: 43122,
      reply_count: 33,
      bookmark_count: 27
    },
    {
      id: 1772829628991946912,
      text: "I learnt more on the job in six months with a supportive team than I ever did at school.",
      retweet_count: 83,
      like_count: 194,
      quote_count: 12,
      impression_count: 37295,
      reply_count: 29,
      bookmark_count: 23
    },
    {
      id: 1727444841683202207,
      text: "I don't like working in fields where I can't stand out. Music production became too accessible and what I did was no longer special so I moved to something harder where my efforts could be noticed.",
      retweet_count: 61,
      like_count: 157,
      quote_count: 7,
      impression_count: 29384,
      reply_count: 24,
      bookmark_count: 18
    },
    {
      id: 1772787456544592133,
      text: "TIL Why does Cloudflare use lava lamps to help with encryption?",
      retweet_count: 104,
      like_count: 476,
      quote_count: 15,
      impression_count: 46873,
      reply_count: 41,
      bookmark_count: 31
    },
    {
      id: 1772778052667470267,
      text: "I'm getting some mad ChatGPT nostalgia where it just cuts out before finishing stuff and doesn't give you the rest of the answer. How is AI a threat to anyone?",
      retweet_count: 89,
      like_count: 711,
      quote_count: 14,
      impression_count: 39458,
      reply_count: 31,
      bookmark_count: 25
    },
    {
      id: 1772574111882961249,
      text: "What do you think the next leap in machine learning and LLMs is going to be like?",
      retweet_count: 317,
      like_count: 633,
      quote_count: 79,
      impression_count: 52144,
      reply_count: 52,
      bookmark_count: 37
    },
    {
      id: 1772837100993569080,
      text: "Just overheard two algorithms discussing privacy. They didn't say much. I guess they prefer to keep things encrypted.",
      retweet_count: 128,
      like_count: 489,
      quote_count: 46,
      impression_count: 44967,
      reply_count: 89,
      bookmark_count: 28
    }
  ].freeze

  def call
    PublicPageData.new(
      engagement_rate_percentage_per_day: engagement_rate_percentage_per_day,
      followers_data_per_day: followers_data_per_day,
      followers_comparison_days: FOLLOWERS_DATA[:comparison_days],
      followers_count: FOLLOWERS_DATA[:count],
      followers_count_change_percentage_text: FOLLOWERS_DATA[:count_change_percentage_text],
      impression_counts_per_day: generate_impression_info,
      impressions_change_since_last_period: IMPRESSIONS_DATA[:change_since_last_week],
      impressions_comparison_days: IMPRESSIONS_DATA[:comparison_days],
      impressions_count: IMPRESSIONS_DATA[:count],
      likes_change_since_last_period: LIKES_DATA[:change_since_last_week],
      likes_comparison_days: LIKES_DATA[:comparison_days],
      likes_count: LIKES_DATA[:count],
      maximum_days_of_data: 7,
      top_posts: generate_top_posts,
      days_of_data_in_recent_count: 3,
      tweet_count_over_available_time_period: 20,
      tweets_change_over_available_time_period: "231 decrease",
      user: NullUser.new,
      demo: true,
      date_range: '7d'
    )
  end

  private

  def engagement_rate_percentage_per_day
    (0..6).map do |i|
      engagement_rate = calculate_engagement_rate_for_day(Date.today - i)
      date_label = (Date.today - i).strftime('%m/%d')
      { date: Date.today - i, data_points: engagement_rate, formatted_label: date_label }
    end.reverse
  end

  def calculate_engagement_rate_for_day(date)
    4.51 - (date.wday * 0.3)
  end

  def followers_data_per_day
    FOLLOWERS_DATA[:counts].map.with_index do |count, i|
      date_label = (Date.today - i).strftime('%m/%d')
      { date: Date.today - i, data_points: count, formatted_label: date_label }
    end
  end

  def generate_impression_info
    IMPRESSIONS_DATA[:counts].map.with_index do |count, i|
      date_label = (Date.today - i).strftime('%m/%d')
      { date: Date.today - i, data_points: count, formatted_label: date_label }
    end
  end

  def generate_top_posts
    CUSTOM_TWEETS.each_with_index.map do |custom_tweet, i|
      tweet = OpenStruct.new(
        text: custom_tweet[:text],
        id: custom_tweet[:id]
      )

      tweet_metrics = [
        OpenStruct.new(
          retweet_count: custom_tweet[:retweet_count],
          like_count: custom_tweet[:like_count],
          quote_count: custom_tweet[:quote_count],
          impression_count: custom_tweet[:impression_count],
          reply_count: custom_tweet[:reply_count],
          bookmark_count: custom_tweet[:bookmark_count]
        )
      ]

      OpenStruct.new(
        text: custom_tweet[:text],
        id: custom_tweet[:id],
        tweet_metrics: tweet_metrics,
        engagement_rate_percentage: calculate_engagement_rate(
          custom_tweet[:retweet_count], custom_tweet[:like_count],
          custom_tweet[:quote_count], custom_tweet[:reply_count],
          custom_tweet[:bookmark_count], custom_tweet[:impression_count]
        ),
        pulled_at: Date.today - i
      )
    end.sort_by { |post| -post.engagement_rate_percentage }
  end


  def calculate_engagement_rate(retweet_count, like_count, quote_count, reply_count, bookmark_count, impression_count)
    ((retweet_count + like_count + quote_count + reply_count + bookmark_count).to_f / impression_count * 100).round(2)
  end

end

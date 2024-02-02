# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


  def create_follower_count_data(identity_id, start_date, end_date, start_followers, end_followers)
    TwitterFollowersCount.where(identity_id: identity_id).destroy_all
    total_days = (end_date - start_date).to_i
    daily_increment = (end_followers - start_followers) / total_days

    (start_date..end_date).each do |date|
      follower_count = start_followers + (date - start_date).to_i * daily_increment
      TwitterFollowersCount.create!(
        identity_id: identity_id,
        followers_count: follower_count.to_s,
        date: date
      )
    end
  end

  # Helper method to create fake Tweet objects
  def create_fake_tweets(identity_id, number_of_tweets)
    number_of_tweets.times do |n|
      Tweet.create!(
        twitter_id: rand(1_000_000_000..9_999_999_999), # Assuming a random large number for twitter_id
        text: "This is a fake tweet ##{n + 1}",
        identity_id: identity_id,
        twitter_created_at: Time.now - rand(1..7).days
      )
    end
  end

  # Helper method to create tweet metrics data with gradual increase or decrease
  def create_tweet_metrics_data(tweet_id, start_date)
    base_retweet_count = 50
    base_quote_count = 25
    base_like_count = 100
    base_quote_count = 25
    base_impression_count = 500
    base_reply_count = 50
    base_bookmark_count = 50
    base_user_profile_clicks = 50

    7.times do |n|
      TweetMetric.create!(
        tweet_id: tweet_id,
        retweet_count: base_retweet_count + rand(-5..5),
        quote_count: base_quote_count + rand(-3..3),
        like_count: base_like_count + rand(-10..10),
        impression_count: base_impression_count + rand(-50..50),
        reply_count: base_reply_count + rand(-5..5),
        bookmark_count: base_bookmark_count + rand(-5..5),
        user_profile_clicks: base_user_profile_clicks + rand(-5..5),
        pulled_at: start_date + n.days,
        created_at: Time.now,
        updated_at: Time.now
      )

      # Update base values for the next day
      base_retweet_count += rand(-2..2)
      base_quote_count += rand(-1..1)
      base_like_count += rand(-5..5)
      base_impression_count += rand(-25..25)
      base_reply_count += rand(-2..2)
      base_bookmark_count += rand(-2..2)
      base_user_profile_clicks += rand(-2..2)
    end
  end

  # Days required in follower seed data
  days_required_in_follower_seed_data = 7.days.ago.to_date
  # days_required_in_follower_seed_data = 14.days.ago.to_date unless days_required_in_follower_seed_data
  # days_required_in_follower_seed_data = 31.days.ago.to_date unless days_required_in_follower_seed_data
  days_required_in_follower_seed_data = 60.days.ago.to_date unless days_required_in_follower_seed_data
  days_required_in_follower_seed_data = 6.months.ago.to_date unless days_required_in_follower_seed_data
  days_required_in_follower_seed_data = 13.months.ago.to_date unless days_required_in_follower_seed_data


if Rails.env.development?

  if User.count.positive?
    # Assuming the first user's identity is what you want to use
    identity_id = User.first.identity.id

    # Create some fake Tweet objects for the identity
    create_fake_tweets(identity_id, 5) # Creating 5 fake tweets for example

    # Assuming you have a Tweet model where each Tweet belongs to an Identity
    tweets = Tweet.where(identity_id: identity_id)

    # Generate 7 days worth of metrics for each tweet
    tweets.each do |tweet|
      start_date = 7.days.ago.to_date
      create_tweet_metrics_data(tweet.id, start_date)
    end

    if days_required_in_follower_seed_data
      # Identity ID from the first user's identity
      identity_id = User.first.identity.id
      TwitterFollowersCount.where(identity_id: identity_id).delete_all
      create_follower_count_data(identity_id, days_required_in_follower_seed_data, Date.today, 1000, 1070)
    end
  end

  AdminUser.create(email: 'ctoynbee@gmail.com', password: 'nittfagm', password_confirmation: 'nittfagm')
end
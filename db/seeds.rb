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
  TwitterFollowersCount.where(identity_id: identity_id).delete_all
  total_days = (end_date - start_date).to_i
  daily_increment = (end_followers - start_followers) / total_days.to_f

  (start_date..end_date).each do |date|
    follower_count = start_followers + ((date - start_date).to_i * daily_increment).round
    TwitterFollowersCount.create!(
      identity_id: identity_id,
      followers_count: follower_count,
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
  def create_tweet_metrics_data(identity_id, start_date, end_date, start_clicks, end_clicks)
    Tweet.where(identity_id: identity_id).find_each do |tweet|
      daily_increment = (end_clicks - start_clicks) / (end_date - start_date).to_i
      clicks_accumulator = start_clicks

      (start_date..end_date).each do |date|
        clicks_for_day = (clicks_accumulator + daily_increment).round
        TweetMetric.create!(
          tweet_id: tweet.id,
          user_profile_clicks: clicks_for_day,
          pulled_at: date.to_time(:utc),
          retweet_count: rand(5..15),
          quote_count: rand(3..12),
          like_count: rand(20..50),
          reply_count: rand(1..10),
          bookmark_count: rand(5..10),
          impression_count: rand(100..300)
        )

        clicks_accumulator = clicks_for_day
      end
    end
  end


  # Days required in follower seed data
  # days_required_in_follower_seed_data = 7.days.ago.to_date
  # days_required_in_follower_seed_data = 14.days.ago.to_date unless days_required_in_follower_seed_data
  # days_required_in_follower_seed_data = 31.days.ago.to_date unless days_required_in_follower_seed_data
  # days_required_in_follower_seed_data = 60.days.ago.to_date unless days_required_in_follower_seed_data
  # days_required_in_follower_seed_data = 6.months.ago.to_date unless days_required_in_follower_seed_data
  # days_required_in_follower_seed_data = 13.months.ago.to_date unless days_required_in_follower_seed_data


if Rails.env.development?

  if User.count.positive?
    # Assuming the first user's identity is what you want to use
    identity_id = User.first.identity.id

    # Create some fake Tweet objects for the identity
    create_fake_tweets(identity_id, 5) # Creating 5 fake tweets for example

    # Assuming you have a Tweet model where each Tweet belongs to an Identity
    tweets = Tweet.where(identity_id: identity_id)

    # Generate 7 days worth of metrics for each tweet
    # tweets.each do |tweet|
    #   start_date = 7.days.ago.to_date
    #   create_tweet_metrics_data(tweet.id, start_date)
    # end

    # if days_required_in_follower_seed_data
      # Identity ID from the first user's identity
      # identity_id = User.first.identity.id
      # TwitterFollowersCount.where(identity_id: identity_id).delete_all
      # create_follower_count_data(identity_id, days_required_in_follower_seed_data, Date.today, 1000, 1070)
    # end

    start_date = 7.days.ago.to_date
    end_date = Date.today
    start_followers = 1000
    end_followers = 1070
    start_clicks = 10
    end_clicks = 70

    create_follower_count_data(identity_id, start_date, end_date, start_followers, end_followers)
    create_tweet_metrics_data(identity_id, start_date, end_date, start_clicks, end_clicks)

  end

  AdminUser.create(email: 'ctoynbee@gmail.com', password: 'nittfagm', password_confirmation: 'nittfagm')
end
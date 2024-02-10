# This file ensures the existence of records required to run the application in every environment (production,
# development, test). It's designed to be idempotent, allowing it to be executed at any point in every environment.
# Data can be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

def create_follower_count_data(identity_id, start_date, end_date, start_followers, end_followers)
  total_days = (end_date - start_date).to_i
  daily_increment = (end_followers - start_followers) / total_days.to_f
  current_followers = start_followers

  (start_date..end_date).each do |date|
    current_followers += (daily_increment * (0.95 + rand(0.1))).round
    TwitterFollowersCount.find_or_create_by!(
      identity_id: identity_id,
      date: date
    ) do |count|
      count.followers_count = current_followers
    end
  end
end

def create_fake_tweets(identity_id, start_date, end_date)
  (start_date..end_date).each do |date|
    rand(2..5).times do
      tweet_text = ["Just released a new track, check it out!", "Exploring the latest in tech. Ruby on Rails is amazing!", "Diving into Golang has been a fantastic journey.", "Had an incredible session in the studio today, new music coming soon!", "Tech, music, and innovation - that's what I live for."].sample
      Tweet.create!(
        twitter_id: rand(1_000_000_000..9_999_999_999),
        text: tweet_text,
        identity_id: identity_id,
        twitter_created_at: date
      )
    end
  end
end

def create_tweet_metrics_data(identity_id, start_date, end_date)
  Tweet.where(identity_id: identity_id, twitter_created_at: start_date..end_date).find_each do |tweet|
    daily_increment = rand(500..1000) # Simulates higher engagement
    TweetMetric.create!(
      tweet_id: tweet.id,
      user_profile_clicks: daily_increment,
      pulled_at: tweet.twitter_created_at + rand(1..24).hours,
      retweet_count: rand(100..500),
      quote_count: rand(50..250),
      like_count: rand(500..2000),
      reply_count: rand(100..500),
      bookmark_count: rand(100..300),
      impression_count: rand(5000..20000)
    )
  end
end

if Rails.env.development?
  AdminUser.find_or_create_by!(email: 'admin@example.com') do |admin|
    admin.password = 'password'
    admin.password_confirmation = 'password'
  end

  unless User.exists?(email: 'demo@echosight.io')
    user = User.create!(
      email: 'demo@echosight.io',
      password: 'demo123',
      password_confirmation: 'demo123',
      confirmed_at: Time.current
    )

    identity = Identity.create!(
      user: user,
      provider: 'twitter',
      uid: 'demo1234567890',
      handle: 'DemoLoftwah',
      description: 'Tech enthusiast, music producer, and avid reader. Always exploring the intersection of technology and creativity.',
      image_url: 'https://github.com/loftwah.png',
      banner_url: 'https://private-user-images.githubusercontent.com/19922556/298599750-cfc9eacb-4e9c-42a3-a3cb-695f685c03e7.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MDc1MjUzMDQsIm5iZiI6MTcwNzUyNTAwNCwicGF0aCI6Ii8xOTkyMjU1Ni8yOTg1OTk3NTAtY2ZjOWVhY2ItNGU5Yy00MmEzLWEzY2ItNjk1ZjY4NWMwM2U3LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDAyMTAlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwMjEwVDAwMzAwNFomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWYwY2JjMjQ3Y2E1ZDM2M2UzOWU4MWRjOTlhNzJjMDkzMGRiNjk3MjcyYWIzMGNiYjUwMWJkZDM5OGFlMmM3OGEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.b1dmswyna9tzuMy_UnkQpUMe1FXU-GAAQanzMSjjcws'
    )

    OauthCredential.create!(
      identity: identity,
      provider: 'twitter',
      token: SecureRandom.hex(20),
      refresh_token: SecureRandom.hex(20),
      expires_at: 1.year.from_now
    )

    # Generate outstanding Twitter followers count data
    create_follower_count_data(identity.id, 365.days.ago.to_date, Date.today, 1000000, 1200000)

    # Generate extensive tweet data
    create_fake_tweets(identity.id, 30.days.ago.to_date, Date.today)

    # Generate extensive tweet metrics data
    create_tweet_metrics_data(identity.id, 30.days.ago.to_date, Date.today)
  end
end

puts 'Seed data loaded successfully with superstar metrics.'

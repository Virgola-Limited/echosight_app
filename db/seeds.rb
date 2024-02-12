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

def create_fake_tweets(identity_id, start_date, end_date, max_tweets_per_day: 15)
  tweets = []
  current_twitter_id = Tweet.maximum(:twitter_id) || 1_000_000_000

  tweet_texts = [
    "Just released a new track, check it out! #music #newrelease",
    "Exploring the latest in tech. Ruby on Rails is amazing! #rubyonrails #tech",
    "Diving into Golang has been a fantastic journey. #golang #programming",
    "Had an incredible session in the studio today, new music coming soon! #studio #musicproduction",
    "Tech, music, and innovation - that's what I live for. #innovation #lifestyle",
    "Check out my latest blog post on web development trends. #webdev #trends",
    "So excited to share my thoughts on the future of AI and machine learning. #AI #machinelearning",
    "Reflecting on a great week of coding and creativity. #coding #creativity",
    "Can't wait for everyone to hear my upcoming collaboration. Stay tuned! #collaboration #music",
    "Exploring new sounds and rhythms has been an amazing experience. #sounddesign #music",
    "Attended an incredible tech conference today, so much to learn! #techconference #learning",
    "Working on a new project that combines tech and music in ways you wouldn't believe. #project #innovation",
    "I believe in the power of technology to transform the music industry. #technology #musicindustry",
    "Nothing beats a day of coding with my favorite playlist in the background. #coding #music",
    "Stay curious, keep learning, and never stop creating. #motivation #lifegoals"
  ]

  (start_date..end_date).each do |date|
    daily_tweet_texts = tweet_texts.shuffle.take(rand(6..max_tweets_per_day))
    daily_tweet_texts.each do |tweet_text|
      current_twitter_id += 1
      tweets << {
        twitter_id: current_twitter_id,
        text: tweet_text,
        identity_id: identity_id,
        twitter_created_at: date
      }
    end
  end

  Tweet.insert_all(tweets)
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
      banner_url: 'https://private-user-images.githubusercontent.com/19922556/304002752-7eb00e4b-4923-4bdd-8e63-b70677da0c88.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MDc3Mjg2MjcsIm5iZiI6MTcwNzcyODMyNywicGF0aCI6Ii8xOTkyMjU1Ni8zMDQwMDI3NTItN2ViMDBlNGItNDkyMy00YmRkLThlNjMtYjcwNjc3ZGEwYzg4LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNDAyMTIlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjQwMjEyVDA4NTg0N1omWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTk2NzlhNzM1NDY2Mjg4YmJhYjY1NGY1MzhkODkyYjI3OGMxMDY5MDQ5M2Q2ODNhNzRhYmRlMWFlN2YwYzRjMWEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JmFjdG9yX2lkPTAma2V5X2lkPTAmcmVwb19pZD0wIn0.ScYDYddG-VoLkJqunjOiLXZFG0mm9T86pwujDTYvo5U'
    )

    create_follower_count_data(identity.id, 365.days.ago.to_date, Date.today, 1000000, 1200000)
    create_fake_tweets(identity.id, 30.days.ago.to_date, Date.today)
    create_tweet_metrics_data(identity.id, 30.days.ago.to_date, Date.today)
  end
end

puts 'Seed data loaded successfully with superstar metrics.'

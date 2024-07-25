# spec/factories/sent_posts.rb
FactoryBot.define do
  factory :sent_post do
    message { "Congratulations @loftwah on topping the leaderboard on Echosight!" }
    post_type { "mention" }
    channel_type { "twitter" }
    tracking_id { SecureRandom.uuid }
    sent_at { Time.current }
    mentioned_users { ["loftwah"] }
  end
end

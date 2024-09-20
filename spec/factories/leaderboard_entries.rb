FactoryBot.define do
  factory :leaderboard_entry do
    association :leaderboard_snapshot
    association :identity
    rank { 1 }
    impressions { 1000 }
    retweets { 100 }
    likes { 100 }
    quotes { 10 }
    replies { 10 }
    bookmarks { 10 }
  end
end
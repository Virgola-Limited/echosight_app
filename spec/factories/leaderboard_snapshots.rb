FactoryBot.define do
  factory :leaderboard_snapshot do
    captured_at { Time.current }
  end
end
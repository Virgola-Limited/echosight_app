FactoryBot.define do
  factory :leaderboard_snapshot do
    date_range { '7_days' }
    captured_at { Time.current }
  end
end
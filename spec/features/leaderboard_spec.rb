require 'rails_helper'

RSpec.feature 'Leaderboard' do
  scenario 'Leaderboard' do
    # Step 1: Visit the leaderboard page when not logged in
    visit leaderboard_path
    expect(page).to have_text('Leaderboard')

    user = create(:user)
    current_user_identity = create(:identity, user: user)

    26.times do
      identity = create(:identity, user: user)
      tweet = create(:tweet, identity: identity)
      create(:tweet_metric, tweet: tweet, impression_count: 400, retweet_count: 10, like_count: 20, quote_count: 5, reply_count: 3, bookmark_count: 2, created_at: 1.day.ago)
    end

    tweet1 = create(:tweet, identity: current_user_identity)
    create(:tweet_metric, tweet: tweet1, impression_count: 100, retweet_count: 10, like_count: 20, quote_count: 5, reply_count: 3, bookmark_count: 2, created_at: 1.day.ago)

    tweet2 = create(:tweet, identity: current_user_identity)
    create(:tweet_metric, tweet: tweet2, impression_count: 200, retweet_count: 20, like_count: 30, quote_count: 10, reply_count: 5, bookmark_count: 3, created_at: 2.days.ago)

    Twitter::LeaderboardSnapshotService.call

    # Step 2: Visit the leaderboard page when not logged in
    visit leaderboard_path
    expect(page).to have_text('Leaderboard')
    within('tbody') do
      expect(page).not_to have_text(current_user_identity.handle)
    end

    # Step 3: Login and check the page again
    login_as(user, scope: :user)
    visit leaderboard_path
    expect(page).to have_text('Leaderboard')
    within('tbody') do
      byebug
      expect(page).to have_text(current_user_identity.handle)
      expect(page).to have_text('26') # Check if the user's rank is 25
    end
  end
end

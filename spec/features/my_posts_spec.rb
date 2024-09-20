require 'rails_helper'

RSpec.feature 'My Posts Page' do
  scenario 'Test My Posts Page' do
    # Context: Visit without signing in
    visit posts_path
    expect(page).to have_content('You must be signed in to access this page.')

    # Context: Visit just after signing up without subscription and signing in
    user = create(:user)
    login_as(user, scope: :user)
    visit posts_path
    expect(page).to have_content('To see your posts you need a valid subscription')
    expect(page).to have_content("For now, we've shown you some example posts to see how it would work.")
    DemoPublicPageService.custom_tweets.each do |custom_tweet|
      expect(page).to have_content(custom_tweet[:text])
    end

    # Context: Visit after subscribing with no posts
    user_with_subscription = create(:user, :with_subscription)
    login_as(user_with_subscription, scope: :user)

    # Context: Visit after subscribing with posts
    tweets = create_list(:tweet, 2, user: user_with_subscription)
    tweets.each do |tweet|
      create(:tweet_metric, tweet: tweet)
    end
    visit posts_path
    tweets.each do |tweet|
      expect(page).to have_content(tweet.text)
    end
  end
end

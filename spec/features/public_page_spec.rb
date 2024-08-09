require 'rails_helper'


DEMO_PAGE_TEXTS = ['Sammy Circuit', 'techsavvysammy', 'Digital explorer, byte-sized philosopher, and AI whisperer. Navigating the tech terrain with a touch of humor and a dash of code. Join me on a journey through the pixels!']

def expect_not_to_have_demo_data
  within('[data-test="user-profile"]') do
    DEMO_PAGE_TEXTS.each do |content|
      expect(page).not_to have_text(content)
    end
  end
end

RSpec.feature 'Public Page Access' do
  before(:each) do
    Capybara.reset_sessions!
    page.driver.browser.manage.delete_all_cookies
  end

  scenario 'Verify public page access and redirections' do
    user = create(:user)

    # Context: Demo page not logged in
    visit public_page_path(:demo)
    expect(page).to have_title("Sammy Circuit's Public Page", wait: 10)
    within('[role="alert"]') do
      expect(page).to have_text('This is a demo page showing how your public page could look')
      expect(page).to have_text('Sign up')
    end
    ##################################

    # Context: When the user is logged in but not signed up to Twitter
    login_user(user)

    visit current_path
    expect(page).to have_text('Dashboard')

    expect(page).to have_title("Sammy Circuit's Public Page", wait: 10)
    within('[role="alert"]') do
      expect(page).to have_text('for the steps to enable your public page')
    end
    within('[data-test="user-profile"]') do
      DEMO_PAGE_TEXTS.each do |content|
        expect(page).to have_text(content)
      end
    end
    ##################################

    # Context: When the user is logged in signed up to Twitter with no subscription
    identity = simulate_twitter_connection(user)
    identity.reload
    visit public_page_path(:demo)
    expect(page).to have_current_path(public_page_path(user.handle))
    expect(page).to have_title("Twitter User's Public Page", wait: 10)

    within('[role="alert"]') do
      expect(page).to have_text('for the steps to enable your public page')
    end
    expect_not_to_have_demo_data
    ##################################

    # Context: When all the criteria are met to show the user's public page
    subscription = create(:subscription, user: user)
    allow(identity).to receive(:enough_data_for_public_page?).and_return(true)
    visit public_page_path(user.handle)
    expect(page).to have_current_path(public_page_path(user.handle))
    expect(page).to have_title("Twitter User's Public Page", wait: 10)

    expect(page).not_to have_text('for the steps to enable your public page')
    expect(page).not_to have_text('Subscribe')
    expect_not_to_have_demo_data
    expect(page.body).to include(user.name)
    expect(page.body).to include(user.identity.description)
    expect(page.body).to include(user.handle)
    ##################################

    # Context: when the user does not have a subscription but is enabled_without_subscription
    user.update(enabled_without_subscription: true)
    subscription.destroy
    visit public_page_path(user.handle)
    expect(page).to have_current_path(public_page_path(user.handle))
    expect(page).to have_title("Twitter User's Public Page", wait: 10)

    expect(page).not_to have_text('This is a demo or inactive page showing')

    # Context: user is logged out and visiting a public page
    logout(:user)
    visit public_page_path(user.handle)
    expect(page).not_to have_text('This is a demo or inactive page showing')
    ##################################

    # Context: Subscription without Twitter connection
    subscription = create(:subscription, user: user)
    identity.destroy
    login_user(user)
    visit public_page_path(user.handle)
    expect(page).to have_current_path(public_page_path(user.handle))
    within('[role="alert"]') do
      expect(page).to have_text('for the steps to enable your public page')
    end
    ##################################

    # Context: user is logged out and visiting a public page
    # logout(:user)
  end

  before do
    tweets_data = [
      { text: "Tweet 1", impressions: 1000000, retweets: 5000, quotes: 1000, likes: 20000, replies: 2000, tweet_created_at: 1.day.ago },
      { text: "Tweet 2", impressions: 900000, retweets: 4500, quotes: 900, likes: 18000, replies: 1800, tweet_created_at: 1.day.ago },
      { text: "Tweet 3", impressions: 800000, retweets: 4000, quotes: 800, likes: 16000, replies: 1600, tweet_created_at: 1.day.ago },
      { text: "Tweet 4", impressions: 700000, retweets: 3500, quotes: 700, likes: 14000, replies: 1400, tweet_created_at: 1.day.ago },
      { text: "Tweet 5", impressions: 600000, retweets: 3000, quotes: 600, likes: 12000, replies: 1200, tweet_created_at: 1.day.ago },
      { text: "Tweet 6", impressions: 500000, retweets: 2500, quotes: 500, likes: 10000, replies: 1000, tweet_created_at: 1.day.ago },
      { text: "Tweet 7", impressions: 400000, retweets: 2000, quotes: 400, likes: 8000, replies: 800, tweet_created_at: 1.day.ago },
      { text: "Tweet 8", impressions: 300000, retweets: 1500, quotes: 300, likes: 6000, replies: 600, tweet_created_at: 1.day.ago },
      { text: "Tweet 9", impressions: 200000, retweets: 1000, quotes: 200, likes: 4000, replies: 400, tweet_created_at: 1.day.ago },
      { text: "Tweet 10", impressions: 100000, retweets: 500, quotes: 100, likes: 2000, replies: 200, tweet_created_at: 1.day.ago }
    ]

    tweets_data.each do |tweet_data|
      tweet = create(:tweet, text: tweet_data[:text], identity: user.identity)
      create(:tweet_metric,
        tweet: tweet,
        impression_count: tweet_data[:impressions],
        retweet_count: tweet_data[:retweets],
        quote_count: tweet_data[:quotes],
        like_count: tweet_data[:likes],
        reply_count: tweet_data[:replies]
      )
    end
    visit public_page_path(user.handle)
  end


  let(:user) { create(:user, :enabled_without_subscription, :with_identity) }

  fscenario "displays top posts table with correct data" do
    within('[id="top-posts-container"]') do
      expect(page).to have_css('[data-test="top-posts-table"]')

      # Check table headers
      expect(page).to have_css('[data-test="post-header"]', text: 'Post')
      expect(page).to have_css('[data-test="impressions-header"]', text: 'Impressions')
      expect(page).to have_css('[data-test="retweets-header"]', text: 'Retweets')
      expect(page).to have_css('[data-test="quotes-header"]', text: 'Quotes')
      expect(page).to have_css('[data-test="likes-header"]', text: 'Likes')
      expect(page).to have_css('[data-test="replies-header"]', text: 'Replies')
      expect(page).to have_css('[data-test="engagement-rate-header"]', text: 'Engagement Rate')
      expect(page).to have_css('[data-test="actions-header"]', text: 'Actions')

      # Check data for each row
      [
        ["Tweet 1", "1M", "5K", "1K", "20K", "2K", "2.8%"],
        ["Tweet 2", "900K", "4.5K", "900", "18K", "1.8K", "2.8%"],
        ["Tweet 3", "800K", "4K", "800", "16K", "1.6K", "2.8%"],
        ["Tweet 4", "700K", "3.5K", "700", "14K", "1.4K", "2.8%"],
        ["Tweet 5", "600K", "3K", "600", "12K", "1.2K", "2.8%"],
        ["Tweet 6", "500K", "2.5K", "500", "10K", "1K", "2.8%"],
        ["Tweet 7", "400K", "2K", "400", "8K", "800", "2.8%"],
        ["Tweet 8", "300K", "1.5K", "300", "6K", "600", "2.8%"],
        ["Tweet 9", "200K", "1K", "200", "4K", "400", "2.8%"],
        ["Tweet 10", "100K", "500", "100", "2K", "200", "2.8%"]
      ].each_with_index do |expected_data, index|
        within("[data-test='post-row-#{index}']") do
          expect(page).to have_css("[data-test='post-text-#{index}']", text: expected_data[0])
          expect(page).to have_css("[data-test='impressions-#{index}']", text: expected_data[1])
          expect(page).to have_css("[data-test='retweets-#{index}']", text: expected_data[2])
          expect(page).to have_css("[data-test='quotes-#{index}']", text: expected_data[3])
          expect(page).to have_css("[data-test='likes-#{index}']", text: expected_data[4])
          expect(page).to have_css("[data-test='replies-#{index}']", text: expected_data[5])
          # expect(page).to have_css("[data-test='engagement-rate-#{index}']", text: expected_data[6])

          tweet = Tweet.find_by(text: expected_data[0])
          expect(page).to have_css("[data-test='actions-#{index}'] a[href='https://twitter.com/user/status/#{tweet.id}']")

        end
        break
      end
    end
  end
end

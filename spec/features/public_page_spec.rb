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
  scenario 'Verify public page access and redirections' do
    user = create(:user)

    # Context: Demo page not logged in
    visit public_page_path(:demo)
    expect(page.title).to eq("Sammy Circuit's Public Page")
    within('[role="alert"]') do
      expect(page).to have_text('This is a demo page showing how your public page could look')
      expect(page).to have_text('Sign up')
    end
    ##################################

    # Context: When the user is logged in but not signed up to Twitter
    login_user(user)

    visit current_path
    expect(page).to have_text('Dashboard')

    expect(page.title).to eq("Sammy Circuit's Public Page")
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

    # Wait for the title to appear correctly
    expect(page).to have_title("Twitter User's Public Page")

    within('[role="alert"]') do
      expect(page).to have_text('for the steps to enable your public page')
    end
    expect_not_to_have_demo_data
    ##################################

    # Context: When all the criteria are met to show the users public page
    subscription = create(:subscription, user: user)
    allow(identity).to receive(:enough_data_for_public_page?).and_return(true)
    visit public_page_path(user.handle)
    expect(page).to have_current_path(public_page_path(user.handle))
    expect(page.title).to eq("Twitter User's Public Page")

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
    expect(page.title).to eq("Twitter User's Public Page")

    expect(page).not_to have_text('This is a demo or inactive page showing')

     # Context user is logged out and visiting a public page
     logout(:user)
     visit public_page_path(user.handle)
     expect(page).not_to have_text('This is a demo or inactive page showing')
    ##################################

    # Context: Subscription without Twitter connection
    subscription = create(:subscription, user: user)
    identity.destroy
    login_user(user)
    visit public_page_path(:demo)
    within('[role="alert"]') do
      expect(page).to have_text('for the steps to enable your public page')
    end
    ##################################
  end
end


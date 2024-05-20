require 'rails_helper'

DEMO_PAGE_TEXTS = ['Sammy Circuit', 'techsavvysammy', 'Digital explorer, byte-sized philosopher, and AI whisperer. Navigating the tech terrain with a touch of humor and a dash of code. Join me on a journey through the pixels!']

RSpec.feature 'Public Page Access' do
  scenario 'Verify public page access and redirections' do
    # Create a user but don't log in
    user = create(:user)

    # Context: When the user is not logged in
    visit public_page_path(:demo)
    expect(page.title).to eq("Sammy Circuit's Public Page")
    within('[role="alert"]') do
      expect(page).to have_text('This is a demo page showing how your public page could look')
      expect(page).to have_text('Sign up')
    end

    # Log in as the created user
    login_user(user)

    # Context: When the user is logged in but not signed up to Twitter
    visit public_page_path(:demo)
    expect(page.title).to eq("Sammy Circuit's Public Page")
    within('[role="alert"]') do
      expect(page).to have_text('This is a demo page showing how your public page could look')
      expect(page).to have_text('Subscribe')
    end
    within('[data-test="user-profile"]') do
      DEMO_PAGE_TEXTS.each do |content|
        expect(page).to have_text(content)
      end
    end

    # Context: When the user is logged in signed up to Twitter with no subscription
    identity = simulate_twitter_connection(user)

    visit public_page_path(:demo)
    expect(page).to have_current_path(public_page_path(user.handle))
    # expect(page.title).to eq("Twitter User's Public Page")

    within('[role="alert"]') do
      expect(page).to have_text('data into your public page')
      expect(page).to have_text('Subscribe')
    end
    within('[data-test="user-profile"]') do
      DEMO_PAGE_TEXTS.each do |content|
        expect(page).not_to have_text(content)
      end
    end

    # Context: When all the criteria are met to show the users public page
    subscription = create(:subscription, user: user)
    allow(identity).to receive(:enough_data_for_public_page?).and_return(true)
    visit public_page_path(user.handle)
    expect(page).to have_current_path(public_page_path(user.handle))
    save_and_open_screenshot
    expect(page.title).to eq("Twitter User's Public Page")
    expect(page).not_to have_text('data into your public page')
    expect(page).not_to have_text('Subscribe')
    DEMO_PAGE_TEXTS.each do |content|
      expect(page.body).not_to include(content)
    end
    expect(page.body).to include(user.name)
    expect(page.body).to include(user.identity.description)
    expect(page.body).to include(user.handle)
  end

end

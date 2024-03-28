require 'rails_helper'

DEMO_PAGE_TEXTS = ['Sammy Circuit', 'techsavvysammy', 'Digital explorer, byte-sized philosopher, and AI whisperer. Navigating the tech terrain with a touch of humor and a dash of code. Join me on a journey through the pixels!']

RSpec.feature 'Public Page Access' do
  scenario 'Verify public page access and redirections' do
    # Create a user but don't log in
    user = create(:user)

    # Attempt to visit the "mine" page without being logged in
    # Expect redirection to the login page
    visit public_page_path(:demo)
    expect(page.body).to include('This is a demo page showing how your public page could look')

    # Log in as the created user
    login_user(user)

    # Now logged in, revisit the "mine" page
    visit public_page_path(:demo)
    within('[data-test="user-profile"]') do
      DEMO_PAGE_TEXTS.each do |content|
        expect(page).to have_text(content)
      end
    end

    # Simulate the user connecting their Twitter account
    simulate_twitter_connection(user)

    # After connecting Twitter, visit the "mine" page again
    visit public_page_path(:demo)
    expect(page).to have_current_path(public_page_path(user.handle))
    DEMO_PAGE_TEXTS.each do |content|
      expect(page.body).not_to include(content)
    end
    expect(page.body).to include(user.name)
    expect(page.body).to include(user.identity.description)
    expect(page.body).to include(user.handle)
  end

end

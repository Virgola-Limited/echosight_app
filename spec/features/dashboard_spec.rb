require 'rails_helper'

RSpec.feature 'Dashboard' do
  scenario 'Dashboard' do
    # Step 1: Visit the dashboard page when not logged in
    visit dashboard_index_path
    expect(page).to have_text('You must be signed in to access this page')

    # Step 2: Visit the dashboard page when logged in
    user = create(:user)
    login_as(user, scope: :user)
    visit dashboard_index_path
    expect(page).to have_text('To start leveraging the full capabilities')
    expect(page).to have_text('Connect to Twitter/X')
    expect(page).to have_text('Subscribe')

    click_button 'Connect to Twitter/X'

  end

end
require 'rails_helper'

RSpec.feature 'User Authentication', type: :feature do
  let!(:user) { create(:user, :unconfirmed) }

  scenario 'User tries various authentication flows' do
    # Step 1: Attempt to login with a non-existent email
    visit new_user_session_path
    fill_in 'Email', with: 'nonexistent@example.com'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    expect(page).to have_content('Invalid login details')

    # Step 2: Attempt to login with the unconfirmed user
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'

    expect(page).to have_content('confirm your Echosight email')

    # Step 3: Try to log in with the wrong password
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'wrongpassword'
    click_button 'Log in'

    expect(page).to have_content('Invalid login details')

    # Step 4: Confirm the user
    user.confirm

    # Step 5: Attempt to login with the correct email but wrong password
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'wrongpassword'
    click_button 'Log in'

    expect(page).to have_content('Invalid login details')

    # Step 6: Finally, try to log in with the correct email and password
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    expect(page).to have_content('Sign out')
  end
end

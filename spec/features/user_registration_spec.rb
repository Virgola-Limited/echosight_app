require 'rails_helper'

RSpec.feature 'User Registration' do
  scenario 'User tries various registration flows' do
    # Step 2: Attempt to sign up with an already taken email
    user = create(:user)
    visit new_user_registration_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_button 'Sign up'

    expect(page).to have_content('Email has already been taken')

    # Step 3: Attempt to sign up without an email
    visit new_user_registration_path
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_button 'Sign up'

    expect(page).to have_content("Email can't be blank")

    # Step 4: Attempt to sign up without a password
    visit new_user_registration_path
    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Password confirmation', with: 'password'
    click_button 'Sign up'

    expect(page).to have_content("Password can't be blank")

    # Step 5: Attempt to sign up without a password confirmation
    visit new_user_registration_path
    fill_in 'Email', with: 'newuser@example.com'
    fill_in 'Password', with: 'password'
    click_button 'Sign up'

    expect(page).to have_content("Password confirmation doesn't match Password")

    # Step 6: Attempt to sign up with mismatched passwords
    visit new_user_registration_path
    fill_in 'Email', with: 'newuser2@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'differentpassword'
    click_button 'Sign up'

    expect(page).to have_content("Password confirmation doesn't match Password")

    # Step 7: Successfully sign up with a new user
    visit new_user_registration_path
    fill_in 'Email', with: 'newuser3@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    click_button 'Sign up'

    expect(page).to have_content('Thank you for signing up with Echosight')
  end
end

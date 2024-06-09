# spec/features/edit_user_spec.rb
require 'rails_helper'

RSpec.feature "EditUser", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in user
    visit edit_user_registration_path
  end

  scenario "user edits their account" do
    # Failure case: incorrect current password
    fill_in 'user_email', with: user.email
    fill_in 'user_current_password', with: 'wrongpassword'
    click_button 'Update'
    expect(page).to have_content("Current password is invalid")

    # Failure case: missing email
    fill_in 'user_email', with: ''
    fill_in 'user_current_password', with: user.password
    click_button 'Update'
    expect(page).to have_content("Email can't be blank")

    # Failure case: password confirmation doesn't match
    fill_in 'user_password', with: 'newpassword'
    fill_in 'user_password_confirmation', with: 'differentpassword'
    fill_in 'user_current_password', with: user.password
    click_button 'Update'
    expect(page).to have_content("Password confirmation doesn't match Password")

    # Successful password change
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'newpassword'
    fill_in 'user_password_confirmation', with: 'newpassword'
    fill_in 'user_current_password', with: user.password
    click_button 'Update'
    expect(page).to have_content("Your Echosight account is updated successfully")

    # Log out and log back in with new password
    # logout(user)
    # visit new_user_session_path
    # save_and_open_screenshot
    # byebug

    # sign_in user.reload

    # # Successful email change (requires confirmation)
    visit edit_user_registration_path
    fill_in 'user_email', with: 'newemail@example.com'
    fill_in 'user_current_password', with: 'newpassword'
    click_button 'Update'
    expect(page).to have_content("sent a confirmation email to your new address.")

    # Log out and confirm new email
    # test confirming email later
  end
end

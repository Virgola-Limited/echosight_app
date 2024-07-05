require 'rails_helper'

RSpec.feature 'User Authentication' do
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

    # New Step 4: Attempt to reset password with a non-existent email
    visit new_user_password_path
    fill_in 'Email', with: 'nonexistent@example.com'
    expect {
      click_button 'Send me reset password instructions'
    }.not_to change { ActionMailer::Base.deliveries.size }
    expect(page).to have_content("If your email is in our system, you'll get a password reset link soon.")

    # Step 5: Attempt to reset password with an existent but unconfirmed email
    visit new_user_password_path
    fill_in 'Email', with:  user.email
    expect {
      click_button 'Send me reset password instructions'
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(page).to have_content("If your email is in our system, you'll get a password reset link soon.")
    last_email = ActionMailer::Base.deliveries.last
    expect(last_email.subject).to include 'Password Reset Instructions'

    # Step 6: Attempt to send confirmation instructions with an invalid email
    visit new_user_confirmation_path
    fill_in 'Email', with: 'invalid@example.com'
    expect {
      click_button 'Resend confirmation instructions'
    }.not_to change { ActionMailer::Base.deliveries.size }

    expect(page).to have_content("If your email is registered with Echosight, you'll get an email with confirmation instructions soon.")

    # Step 7: Attempt to send confirmation instructions with a valid, unconfirmed email
    visit new_user_confirmation_path
    fill_in 'Email', with: user.email
    expect {
      click_button 'Resend confirmation instructions'

    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    expect(page).to have_content("If your email is registered with Echosight, you'll get an email with confirmation instructions soon.")

    # Step 8: Confirm the user and attempt to send confirmation instructions again
    user.confirm
    visit new_user_confirmation_path
    fill_in 'Email', with: user.email
    expect {
      click_button 'Resend confirmation instructions'
    }.not_to change { ActionMailer::Base.deliveries.size }

    expect(page).to have_content("If your email is registered with Echosight, you'll get an email with confirmation instructions soon.")

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

    expect(page).to have_content('signed in to Echosight')
    expect(page).to have_current_path(dashboard_index_path)

    # Step 7: Log out
    # TODO: Doesnt work on CI fix later
    unless ENV['CI']
      logout_user(user)
      expect(page).to have_content("You're now signed out of Echosight.")

      # Step 8: Lock account with too many failed attempts
      visit new_user_session_path

      6.times do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'wrongpassword'
        click_button 'Log in'
      end
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(user.email)
      expect(email.subject).to eq('Echosight Account Unlock Instructions')
      expect(email.body.encoded).to include('locked')
    end
  end
end

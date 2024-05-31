require 'rails_helper'

RSpec.describe 'Subscription' do
  scenario 'Subscription page in various states' do
    # Context: When the user is not logged in
    visit subscription_path
    expect(page).to have_text('You must be signed in to access this page')


    # Context: when the user has just signed up and confirmed
    user = create(:user)
    login_as(user, scope: :user)
    visit subscription_path
    expect(page).to have_text('Setup your subscription below to enable your public page')
    expect(page).not_to have_text('We are currently offering')

    # Context: when the user is eligible for a trial
    allow_any_instance_of(User).to receive(:eligible_for_trial?).and_return(true)
    visit subscription_path
    expect(page).to have_text('We are currently offering')
  end
end

require 'rails_helper'

RSpec.feature 'Devise Emails', type: :feature do
  let(:user) { create(:user) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  scenario 'sends a confirmation email' do
    user.confirmation_token = Devise.friendly_token
    user.confirmation_sent_at = Time.current
    user.save!

    expect {
      Devise::Mailer.confirmation_instructions(user, user.confirmation_token).deliver_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to eq('Echosight Confirmation Instructions')
    expect(email.body.encoded).to include('Click Here to Confirm Your Account')
  end

  scenario 'sends a reset password email' do
    user.reset_password_token = Devise.friendly_token
    user.reset_password_sent_at = Time.current
    user.save!

    expect {
      Devise::Mailer.reset_password_instructions(user, user.reset_password_token).deliver_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to eq('Echosight Password Reset Instructions')
    expect(email.body.encoded).to include('Reset Your Password')
  end

  scenario 'sends an unlock instructions email' do
    user.lock_access!
    user.unlock_token = Devise.friendly_token
    user.locked_at = Time.current
    user.save!

    expect {
      Devise::Mailer.unlock_instructions(user, user.unlock_token).deliver_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to eq('Echosight Account Unlock Instructions')
    expect(email.body.encoded).to include('Unlock Your Account')
  end

  scenario 'sends an email change confirmation email' do
    user.unconfirmed_email = 'newemail@example.com'
    user.confirmation_token = Devise.friendly_token
    user.confirmation_sent_at = Time.current
    user.save!

    expect {
      Devise::Mailer.email_changed(user).deliver_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to eq('Echosight Email Address Updated')
  end

  scenario 'sends a password change notification email' do
    user.save!

    expect {
      Devise::Mailer.password_change(user).deliver_now
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to eq('Echosight Password Updated')
  end
end

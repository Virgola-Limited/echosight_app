require 'rails_helper'

RSpec.describe UsersWithoutSubscriptionEmailJob, type: :job do
  let(:one_week_ago) { 1.week.ago }

  let!(:eligible_user) { create(:user, created_at: one_week_ago - 1.day) }
  let!(:ineligible_user_with_subscription) { create(:user, :with_subscription, created_at: one_week_ago - 1.day) }
  let!(:ineligible_user_with_recent_signup) { create(:user, created_at: Time.now) }
  let!(:ineligible_user_with_sent_email) do
    user = create(:user, created_at: one_week_ago - 1.day)
    create(:sent_email, user: user, email_type: 'users_without_subscription_email')
    user
  end

  before do
    allow(UserMailer).to receive_message_chain(:users_without_subscription_email, :deliver_now)
  end

  it 'sends feedback request emails to eligible users only' do
    described_class.perform_async
    UsersWithoutSubscriptionEmailJob.drain

    expect(UserMailer).to have_received(:users_without_subscription_email).with(eligible_user)
    expect(UserMailer).not_to have_received(:users_without_subscription_email).with(ineligible_user_with_subscription)
    expect(UserMailer).not_to have_received(:users_without_subscription_email).with(ineligible_user_with_recent_signup)
    expect(UserMailer).not_to have_received(:users_without_subscription_email).with(ineligible_user_with_sent_email)
  end
end

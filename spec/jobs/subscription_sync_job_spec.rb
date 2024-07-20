# spec/jobs/subscription_sync_job_spec.rb
require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe SubscriptionSyncJob, type: :job do
  let(:user) { create(:user) }
  let!(:active_subscription) { create(:subscription, active: true, user: user) }

  before do
    Sidekiq::Testing.inline!
  end

  it 'processes only active subscriptions' do
    expect(CustomStripe::SubscriptionChecker).to receive(:check_subscription).with(active_subscription).once
    SubscriptionSyncJob.perform_async
  end
end

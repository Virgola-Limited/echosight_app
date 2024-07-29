require 'rails_helper'

RSpec.describe CustomStripe::SubscriptionChecker do
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user, stripe_subscription_id: 'sub_test', status: 'active', active: true) }

  before do
    allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_subscription)
  end

  context 'when subscription status changes' do
    let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_test', status: 'trialing', cancel_at_period_end: false) }

    it 'updates the subscription' do
      expect(subscription).to receive(:update).with(status: 'trialing', active: true)
      described_class.check_subscription(subscription)
    end
  end

  context 'when subscription status does not change' do
    let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_test', status: 'active', cancel_at_period_end: false) }

    it 'does not update the subscription' do
      expect(subscription).not_to receive(:update)
      described_class.check_subscription(subscription)
    end
  end
end

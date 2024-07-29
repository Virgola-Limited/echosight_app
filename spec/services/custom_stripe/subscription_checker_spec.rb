require 'rails_helper'

RSpec.describe CustomStripe::SubscriptionChecker do
  let(:user) { create(:user) }
  let(:subscription) { create(:subscription, user: user, stripe_subscription_id: 'sub_test', status: 'active', current_period_end: 1.month.from_now) }
  let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_test', status: 'canceled', current_period_end: Time.current.to_i) }

  before do
    allow(Stripe::Subscription).to receive(:retrieve).with(subscription.stripe_subscription_id).and_return(stripe_subscription)
  end

  describe '.check_subscription' do
    context 'when stripe_subscription_id is present' do
      it 'retrieves the Stripe subscription' do
        expect(Stripe::Subscription).to receive(:retrieve).with(subscription.stripe_subscription_id)
        described_class.check_subscription(subscription)
      end

      it 'calls update_local_subscription with the local and Stripe subscription' do
        expect(described_class).to receive(:update_local_subscription).with(subscription, stripe_subscription)
        described_class.check_subscription(subscription)
      end
    end

    context 'when stripe_subscription_id is not present' do
      it 'does not retrieve the Stripe subscription' do
        subscription.stripe_subscription_id = nil
        expect(Stripe::Subscription).not_to receive(:retrieve)
        described_class.check_subscription(subscription)
      end
    end
  end

  describe '.update_local_subscription' do
    context 'when the status has changed' do
      it 'updates the local subscription with the new status and current_period_end' do
        described_class.update_local_subscription(subscription, stripe_subscription)
        subscription.reload
        expect(subscription.status).to eq('canceled')
        expect(subscription.current_period_end).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when the status has not changed' do
      let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_test', status: 'active', current_period_end: Time.current.to_i) }

      it 'does not update the local subscription' do
        expect(subscription).not_to receive(:update)
        described_class.update_local_subscription(subscription, stripe_subscription)
      end
    end
  end
end

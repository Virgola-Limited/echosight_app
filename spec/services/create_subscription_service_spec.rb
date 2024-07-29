require 'rails_helper'

RSpec.describe CreateSubscriptionService do
  let(:user) { create(:user, stripe_customer_id: 'cus_123') }
  let(:plan_id) { 'price_123' }
  let(:stripe_token) { 'tok_visa' }
  let(:service) { described_class.new(user, plan_id, stripe_token) }

  let(:stripe_customer) { double('Stripe::Customer', id: 'cus_123') }
  let(:stripe_payment_method) { double('Stripe::PaymentMethod', id: 'pm_123') }
  let(:stripe_subscription) { double('Stripe::Subscription', id: 'sub_123', status: 'active', current_period_end: 1.month.from_now.to_i) }

  before do
    allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
    allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
    allow(Stripe::PaymentMethod).to receive(:create).and_return(stripe_payment_method)
    allow(Stripe::PaymentMethod).to receive(:attach)
    allow(Stripe::Customer).to receive(:update)
    allow(Stripe::Subscription).to receive(:create).and_return(stripe_subscription)
    allow(SubscriptionMailer).to receive_message_chain(:subscription_confirmation, :deliver_later)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  describe '#call' do
    context 'when plan_id is not present' do
      let(:plan_id) { nil }

      it 'returns an error' do
        result = service.call
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Please select a subscription plan.')
      end
    end

    context 'when plan_id is present' do
      it 'creates or retrieves a Stripe customer' do
        expect(Stripe::Customer).to receive(:retrieve).with(user.stripe_customer_id).and_return(stripe_customer)
        service.call
      end

      it 'creates a new Stripe customer if none exists' do
        user.update(stripe_customer_id: nil)
        expect(Stripe::Customer).to receive(:create).with(email: user.email).and_return(stripe_customer)
        service.call
      end

      it 'attaches a payment method if stripe_token is present' do
        expect(Stripe::PaymentMethod).to receive(:create).with({ type: 'card', card: { token: stripe_token } }).and_return(stripe_payment_method)
        expect(Stripe::PaymentMethod).to receive(:attach).with(stripe_payment_method.id, { customer: stripe_customer.id })
        expect(Stripe::Customer).to receive(:update).with(stripe_customer.id, { invoice_settings: { default_payment_method: stripe_payment_method.id } })
        service.call
      end

      it 'deactivates existing subscriptions' do
        active_subscriptions = double('active_subscriptions', exists?: true)
        allow(user.subscriptions).to receive(:active).and_return(active_subscriptions)
        expect(active_subscriptions).to receive(:update_all).with(status: 'canceled')
        service.call
      end

      it 'creates a new Stripe subscription' do
        expect(Stripe::Subscription).to receive(:create).with(
          hash_including(
            customer: stripe_customer.id,
            items: [{ price: plan_id }],
            trial_period_days: ENV.fetch('TRIAL_PERIOD_DAYS', 0).to_i,
            expand: ['latest_invoice.payment_intent']
          )
        ).and_return(stripe_subscription)
        service.call
      end

      it 'creates a new local subscription' do
        expect { service.call }.to change { user.subscriptions.count }.by(1)
        new_subscription = user.subscriptions.last
        expect(new_subscription.stripe_subscription_id).to eq('sub_123')
        expect(new_subscription.stripe_price_id).to eq(plan_id)
        expect(new_subscription.status).to eq('active')
      end

      it 'sends a confirmation email' do
        expect(SubscriptionMailer).to receive_message_chain(:subscription_confirmation, :deliver_later)
        service.call
      end

      context 'when an exception occurs' do
        before do
          allow(Stripe::Customer).to receive(:retrieve).and_raise(StandardError, 'Stripe error')
        end

        it 'notifies ExceptionNotifier' do
          service.call
          expect(ExceptionNotifier).to have_received(:notify_exception).with(instance_of(StandardError))
        end

        it 'returns an error' do
          result = service.call
          expect(result[:success]).to be_falsey
          expect(result[:error]).to eq('Stripe error')
        end
      end
    end
  end
end

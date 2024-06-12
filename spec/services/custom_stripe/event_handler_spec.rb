# spec/services/custom_stripe/event_handler_spec.rb
require 'rails_helper'

RSpec.describe CustomStripe::EventHandler, type: :service do
  let!(:user) { create(:user, stripe_customer_id: 'cus_123') }
  let!(:subscription) { create(:subscription, user: user, stripe_subscription_id: 'sub_123') }
  let(:product) { OpenStruct.new(id: 'prod_123', name: 'Test Product') }
  let(:price) { OpenStruct.new(id: 'price_123', product: 'prod_123') }
  let(:subscription_item) { OpenStruct.new(price: price) }
  let(:stripe_subscription) { OpenStruct.new(id: 'sub_123', items: OpenStruct.new(data: [subscription_item]), status: 'active', current_period_end: Time.current.to_i) }
  let(:event) { OpenStruct.new(type: 'customer.subscription.created', data: OpenStruct.new(object: stripe_subscription)) }

  before do
    allow(Stripe::Price).to receive(:retrieve).with('price_123').and_return(price)
    allow(Stripe::Product).to receive(:retrieve).with('prod_123').and_return(product)
    allow(Notifications::SlackNotifier).to receive(:call)
  end

  describe '#call' do
    subject { described_class.new.call(event) }

    context 'when subscription is created' do
      it 'sends a subscription created notification' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: "Subscription created: Product: Test Product, User: #{user.email}, Follow this user: https://x.com/")
        subject
      end
    end

    context 'when subscription is updated' do
      let(:event) { OpenStruct.new(type: 'customer.subscription.updated', data: OpenStruct.new(object: stripe_subscription)) }

      it 'sends a subscription updated notification' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: "Subscription updated: Product: Test Product, User: #{user.email}")
        subject
      end

      # it 'updates the user subscription' do
      #   expect(subscription).to receive(:update).with(
      #     status: 'active',
      #     current_period_end: an_instance_of(DateTime)
      #   )
      #   subject
      # end
    end

    context 'when subscription is deleted' do
      let(:event) { OpenStruct.new(type: 'customer.subscription.deleted', data: OpenStruct.new(object: stripe_subscription)) }

      it 'sends a subscription deleted notification' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: "Subscription deleted: Product: Test Product, User: #{user.email}")
        subject
      end

      # it 'updates the user subscription status to canceled' do
      #   expect(subscription).to receive(:update).with(status: 'canceled')
      #   subject
      # end
    end

    context 'when subscription is resumed' do
      let(:event) { OpenStruct.new(type: 'customer.subscription.resumed', data: OpenStruct.new(object: stripe_subscription)) }

      it 'sends a subscription resumed notification' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: "Subscription resumed: Product: Test Product, User: #{user.email}")
        subject
      end
    end

    context 'when subscription is paused' do
      let(:event) { OpenStruct.new(type: 'customer.subscription.paused', data: OpenStruct.new(object: stripe_subscription)) }

      it 'sends a subscription paused notification' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: "Subscription paused: Product: Test Product, User: #{user.email}")
        subject
      end
    end

    context 'when event type is unhandled' do
      let(:event) { OpenStruct.new(type: 'unhandled.event.type', data: OpenStruct.new(object: stripe_subscription)) }

      it 'logs the unhandled event type' do
        expect(Rails.logger).to receive(:info).with("Unhandled event type: unhandled.event.type")
        subject
      end
    end
  end
end

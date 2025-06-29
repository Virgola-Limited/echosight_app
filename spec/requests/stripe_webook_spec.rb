require 'rails_helper'

RSpec.describe 'Stripe Webhook', type: :request do
  let!(:user) { create(:user, email: 'test@example.com') }
  let!(:subscription) { create(:subscription, user: user, stripe_subscription_id: 'sub_test', status: 'active', current_period_end: 1.month.from_now) }

  before do
    allow(Notifications::SlackNotifier).to receive(:call)

    allow(Stripe::Webhook).to receive(:construct_event).and_return(
      Stripe::Event.construct_from(
        id: 'evt_test',
        type: event_type,
        data: {
          object: {
            id: 'sub_test',
            status: stripe_status,
            cancel_at_period_end: false,
            current_period_end: Time.current.to_i,
            items: {
              data: [
                {
                  price: {
                    id: 'price_123'
                  }
                }
              ]
            }
          }
        }
      )
    )
  end

  def stripe_event_payload(type, status)
    {
      id: 'evt_test',
      type: type,
      data: {
        object: {
          id: 'sub_test',
          status: status,
          cancel_at_period_end: false,
          current_period_end: Time.current.to_i,
          items: {
            data: [
              {
                price: {
                  id: 'price_123'
                }
              }
            ]
          }
        }
      }
    }
  end

  describe 'POST /stripe/webhook' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'Stripe-Signature' => 't=1234567890,v1=fake_signature'
      }
    end

    context 'when the subscription is created' do
      let(:event_type) { 'customer.subscription.created' }
      let(:stripe_status) { 'trialing' }

      it 'sends a Slack notification with full event details and updates the subscription' do
        post '/stripe/webhook', params: stripe_event_payload(event_type, stripe_status).to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq('trialing')
        expect(subscription.reload.current_period_end).to be_within(5.seconds).of(Time.current)

        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: a_string_matching(/Received Stripe event: #{event_type}/)))
        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: /Subscription created/))
      end
    end

    context 'when the subscription is updated' do
      let(:event_type) { 'customer.subscription.updated' }
      let(:stripe_status) { 'active' }

      it 'sends a Slack notification with full event details and updates the subscription' do
        post '/stripe/webhook', params: stripe_event_payload(event_type, stripe_status).to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq('active')
        expect(subscription.reload.current_period_end).to be_within(5.seconds).of(Time.current)

        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: a_string_matching(/Received Stripe event: #{event_type}/)))
        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: /Subscription updated/))
      end
    end

    context 'when the subscription is deleted' do
      let(:event_type) { 'customer.subscription.deleted' }
      let(:stripe_status) { 'canceled' }

      it 'sends a Slack notification with full event details and updates the subscription' do
        post '/stripe/webhook', params: stripe_event_payload(event_type, stripe_status).to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq('canceled')
        expect(subscription.reload.current_period_end).to be_within(5.seconds).of(Time.current)

        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: a_string_matching(/Received Stripe event: #{event_type}/)))
        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: /Subscription deleted/))
      end
    end

    context 'when the subscription is not found' do
      let(:event_type) { 'customer.subscription.updated' }
      let(:stripe_status) { 'active' }

      before do
        subscription.destroy
      end

      it 'sends a Slack notification to the errors channel' do
        post '/stripe/webhook', params: stripe_event_payload(event_type, stripe_status).to_json, headers: headers

        expect(response).to have_http_status(:ok)
        error_message = "Failed to find user subscription for Stripe ID sub_test"
        expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: error_message, channel: :errors))
      end
    end
  end
end

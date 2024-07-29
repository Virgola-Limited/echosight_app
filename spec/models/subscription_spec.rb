require 'rails_helper'

RSpec.describe Subscription, type: :model do
  let(:user) { create(:user) }
  let(:subscription) { build(:subscription, user: user) }

  describe 'validations' do
    it 'validates presence of stripe_subscription_id' do
      subscription.stripe_subscription_id = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:stripe_subscription_id]).to include("can't be blank")
    end

    it 'validates uniqueness of stripe_subscription_id' do
      create(:subscription, stripe_subscription_id: subscription.stripe_subscription_id)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:stripe_subscription_id]).to include("has already been taken")
    end

    it 'validates presence of stripe_price_id' do
      subscription.stripe_price_id = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:stripe_price_id]).to include("can't be blank")
    end

    it 'validates presence of user' do
      subscription.user = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:user]).to include("can't be blank")
    end

    it 'validates only one active subscription per user' do
      create(:subscription, user: user, active: true)
      new_subscription = build(:subscription, user: user, active: true)
      expect(new_subscription).not_to be_valid
      expect(new_subscription.errors[:user]).to include('can only have one active subscription')
    end
  end

  describe 'callbacks' do
    context 'after save' do
      it 'calls notify_status_change if saved_change_to_active?' do
        allow(subscription).to receive(:saved_change_to_active?).and_return(true)
        expect(subscription).to receive(:notify_status_change)
        subscription.save
      end

      it 'does not call notify_status_change if not saved_change_to_active?' do
        allow(subscription).to receive(:saved_change_to_active?).and_return(false)
        expect(subscription).not_to receive(:notify_status_change)
        subscription.save
      end
    end
  end

  describe '#notify_status_change' do
    let(:message) { "Subscription #{subscription.stripe_subscription_id} for user #{user.email} is now #{subscription.active? ? 'active' : 'inactive'}." }

    before do
      allow(Notifications::SlackNotifier).to receive(:call)
    end

    it 'sends a notification to Slack with the correct message when activated' do
      subscription.update!(active: false) # Set initial state
      subscription.update!(active: true)  # Trigger activation
      expect(Notifications::SlackNotifier).to have_received(:call).with(message: "Subscription #{subscription.stripe_subscription_id} for user #{subscription.user.email} is now active.")
    end

    it 'sends a notification to Slack with the correct message when deactivated' do
      subscription.update!(active: true)  # Set initial state
      subscription.update!(active: false) # Trigger deactivation
      expect(Notifications::SlackNotifier).to have_received(:call).with(message: "Subscription #{subscription.stripe_subscription_id} for user #{subscription.user.email} is now inactive.")
    end
  end
end

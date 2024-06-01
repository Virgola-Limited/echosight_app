require 'rails_helper'

RSpec.describe CreateStripeCustomerWorkerJob do
  describe '#perform' do
    let(:user) { create(:user) }

    context 'when user does not have a stripe_customer_id' do
      it 'creates a Stripe customer and updates the user' do
        allow(Stripe::Customer).to receive(:create).and_return(double('Customer', id: 'cus_test123'))

        described_class.new.perform(user.id)

        expect(user.reload.stripe_customer_id).to eq('cus_test123')
        expect(Stripe::Customer).to have_received(:create).with(email: user.email)
      end
    end

    context 'when Stripe API call fails' do
      it 'raises a Stripe error and does not update the user' do
        allow(Stripe::Customer).to receive(:create).and_raise(Stripe::StripeError.new('Failed to create customer'))

        expect {
          described_class.new.perform(user.id)
        }.to raise_error(Stripe::StripeError)

        expect(user.reload.stripe_customer_id).to be_nil
      end
    end

    context 'when user already has a stripe_customer_id' do
      before { user.update!(stripe_customer_id: 'cus_existing123') }

      it 'does nothing' do
        expect(Stripe::Customer).not_to receive(:create)

        described_class.new.perform(user.id)

        expect(user.reload.stripe_customer_id).to eq('cus_existing123')
      end
    end
  end
end

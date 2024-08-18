require 'rails_helper'

RSpec.describe Identity, type: :model do
  describe '.syncable' do
    let!(:confirmed_user_with_valid_identity_and_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user)
      create(:subscription, user: user)
      user.identity
    end

    let!(:confirmed_user_with_valid_identity_and_enabled_without_subscription) do
      user = create(:user, confirmed_at: Time.current, enabled_without_subscription: true)
      create(:identity, user: user)
      user.identity
    end

    let!(:confirmed_user_without_identity) do
      create(:user, confirmed_at: Time.current)
    end

    let!(:confirmed_user_with_invalid_identity) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user, provider: 'facepalm')
      user.identity
    end

    let!(:confirmed_user_with_valid_identity_but_no_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user)
      create(:subscription, :inactive, user: user)
      user.identity
    end

    let!(:unconfirmed_user) do
      user = create(:user, confirmed_at: nil)
      create(:identity, user: user)
      create(:subscription, user: user)
      user.identity
    end

    let!(:identity_without_user) do
      create(:identity, :syncable_without_user)
    end

    it 'returns only identities that are syncable' do
      expect(Identity.syncable).to match_array([
        confirmed_user_with_valid_identity_and_active_subscription,
        confirmed_user_with_valid_identity_and_enabled_without_subscription,
        identity_without_user
      ])
    end
  end

  describe '#disable_versioning_if_uid_updated' do
    let(:identity) { create(:identity, uid: 'old_uid') }

    context 'when uid is changed and has been updated before' do
      before do
        allow(identity).to receive(:uid_updated_before?).and_return(true)
        allow(PaperTrail.request).to receive(:disable_model)
      end

      it 'disables versioning for the model' do
        identity.uid = 'new_uid'
        identity.save

        expect(PaperTrail.request).to have_received(:disable_model).with(Identity)
      end
    end

    context 'when uid is not changed' do
      before do
        allow(PaperTrail.request).to receive(:disable_model)
      end

      it 'does not disable versioning' do
        identity.save

        expect(PaperTrail.request).not_to have_received(:disable_model)
      end
    end

    context 'when uid is changed but has not been updated before' do
      before do
        allow(identity).to receive(:uid_updated_before?).and_return(false)
        allow(PaperTrail.request).to receive(:disable_model)
      end

      it 'does not disable versioning' do
        identity.uid = 'new_uid'
        identity.save

        expect(PaperTrail.request).not_to have_received(:disable_model)
      end
    end
  end
end

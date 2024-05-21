require 'rails_helper'

RSpec.describe User, type: :model do
  fdescribe '.syncable' do
    let!(:confirmed_user_with_valid_identity_and_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user, provider: 'twitter2')
      create(:subscription, user: user, active: true)
      user
    end

    let!(:confirmed_user_without_identity) do
      create(:user, confirmed_at: Time.current)
    end

    let!(:confirmed_user_with_invalid_identity) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user, provider: 'facepalm')
      user
    end

    let!(:confirmed_user_with_valid_identity_but_no_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user, provider: 'twitter2')
      create(:subscription, user: user, active: false)
      user
    end

    let!(:unconfirmed_user) do
      user = create(:user, confirmed_at: nil)
      create(:identity, user: user, provider: 'twitter2')
      create(:subscription, user: user, active: true)
      user
    end

    it 'returns only users who are confirmed, have a valid identity, and an active subscription' do
      expect(User.syncable).to match_array([confirmed_user_with_valid_identity_and_active_subscription])
    end
  end

  describe '#syncable?' do
    context 'when the user is not confirmed' do
      let(:user) { create(:user, confirmed_at: nil) }

      it 'returns false' do
        expect(user.syncable?).to be_falsey
      end
    end

    context 'when the user is confirmed' do
      context 'when the user has no identity' do
        let(:user) { create(:user, confirmed_at: Time.current) }

        it 'returns false' do
          expect(user.syncable?).to be_falsey
        end
      end

      context 'when the user has an identity' do
        context 'when the identity is not valid' do
          let!(:identity) { create(:identity, user: user, provider: 'facepalm') }
          let(:user) { create(:user, confirmed_at: Time.current) }

          it 'returns false' do
            expect(user.syncable?).to be_falsey
          end
        end

        context 'when the identity is valid' do
          context 'when the user does not have an active subscription' do
            let(:user) { create(:user, confirmed_at: Time.current) }

            it 'returns false' do
              expect(user.syncable?).to be_falsey
            end
          end

          context 'when the user has an active subscription' do
            let!(:identity) { create(:identity, user: user)}
            let(:user) { create(:user, confirmed_at: Time.current) }
            let!(:subscription) { create(:subscription, user: user, active: true) }

            it 'returns true' do
              expect(user.syncable?).to be_truthy
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
#  ad_campaign                  :string
#  confirmation_sent_at         :datetime
#  confirmation_token           :string
#  confirmed_at                 :datetime
#  consumed_timestep            :integer
#  current_sign_in_at           :datetime
#  current_sign_in_ip           :string
#  email                        :string           default(""), not null
#  enabled_without_subscription :boolean          default(FALSE)
#  encrypted_password           :string           default(""), not null
#  failed_attempts              :integer          default(0), not null
#  invitation_accepted_at       :datetime
#  invitation_created_at        :datetime
#  invitation_limit             :integer
#  invitation_sent_at           :datetime
#  invitation_token             :string
#  invitations_count            :integer          default(0)
#  invited_by_type              :string
#  last_name                    :string
#  last_sign_in_at              :datetime
#  last_sign_in_ip              :string
#  locked_at                    :datetime
#  name                         :string
#  otp_required_for_login       :boolean
#  otp_secret                   :string
#  remember_created_at          :datetime
#  reset_password_sent_at       :datetime
#  reset_password_token         :string
#  sign_in_count                :integer          default(0), not null
#  unconfirmed_email            :string
#  unlock_token                 :string
#  vip_since                    :date
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  campaign_id                  :string
#  invited_by_id                :bigint
#  stripe_customer_id           :string
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by            (invited_by_type,invited_by_id)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_stripe_customer_id    (stripe_customer_id)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  fdescribe 'Scopes' do
    let!(:user_with_subscription) { create(:user) }
    let!(:active_subscription) { create(:subscription, user: user_with_subscription, status: 'active') }

    let!(:user_without_subscription) { create(:user) }
    let!(:inactive_subscription) { create(:subscription, :inactive, user: user_without_subscription) }

    let!(:user_no_subscription) { create(:user) }

    let!(:user_with_identity) { create(:user) }
    let!(:identity) { create(:identity, user: user_with_identity) }

    let!(:user_without_identity) { create(:user) }

    let!(:user_trialing) { create(:user) }
    let!(:trialing_subscription) { create(:subscription, :trialing, user: user_trialing) }

    # Test for with_subscription scope
    describe '.with_subscription' do
      it 'includes users with active subscriptions' do
        expect(User.with_subscription).to include(user_with_subscription)
      end

      it 'does not include users without active subscriptions' do
        expect(User.with_subscription).not_to include(user_without_subscription)
        expect(User.with_subscription).not_to include(user_no_subscription)
      end
    end

    # Test for without_subscription scope
    describe '.without_subscription' do
      it 'includes users without any subscriptions' do
        expect(User.without_subscription).to include(user_no_subscription)
      end

      it 'includes users with non-active subscriptions' do
        expect(User.without_subscription).to include(user_without_subscription)
      end

      it 'does not include users with active subscriptions' do
        expect(User.without_subscription).not_to include(user_with_subscription)
      end
    end

    # Test for without_identity scope
    describe '.without_identity' do
      it 'includes users without identity' do
        expect(User.without_identity).to include(user_without_identity)
      end

      it 'does not include users with identity' do
        expect(User.without_identity).not_to include(user_with_identity)
      end
    end

    # Test for trialing scope
    describe '.trialing' do
      it 'includes users with trialing subscriptions' do
        expect(User.trialing).to include(user_trialing)
      end

      it 'does not include users without trialing subscriptions' do
        expect(User.trialing).not_to include(user_with_subscription)
        expect(User.trialing).not_to include(user_without_subscription)
        expect(User.trialing).not_to include(user_no_subscription)
      end
    end
  end


  context 'create user' do
    it 'creates a user with an otp_secret' do
      user = create(:user)
      expect(user.otp_secret).to be_present
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
          let!(:identity) { create(:identity, user:, provider: 'facepalm') }
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
            let!(:identity) { create(:identity, user:) }
            let(:user) { create(:user, confirmed_at: Time.current) }
            let!(:subscription) { create(:subscription, user:) }

            it 'returns true' do
              expect(user.syncable?).to be_truthy
            end
          end

          context 'when the user is enabled_without_subscription' do
            let!(:identity) { create(:identity, user:) }
            let(:user) { create(:user, confirmed_at: Time.current, enabled_without_subscription: true) }

            it 'returns true' do
              expect(user.syncable?).to be_truthy
            end
          end
        end
      end
    end
  end
end

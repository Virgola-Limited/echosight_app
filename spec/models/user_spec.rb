# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
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
  context 'create user' do
    it 'creates a user with an otp_secret' do
      user = create(:user)
      expect(user.otp_secret).to be_present
    end
  end

  describe '.syncable' do
    let!(:confirmed_user_with_valid_identity_and_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user:, provider: 'twitter2')
      create(:subscription, user:, active: true)
      user
    end

    let!(:confirmed_user_with_valid_identity_and_enabled_without_subscription) do
      user = create(:user, confirmed_at: Time.current, enabled_without_subscription: true)
      create(:identity, user:, provider: 'twitter2')
      user
    end

    let!(:confirmed_user_without_identity) do
      create(:user, confirmed_at: Time.current)
    end

    let!(:confirmed_user_with_invalid_identity) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user:, provider: 'facepalm')
      user
    end

    let!(:confirmed_user_with_valid_identity_but_no_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user:, provider: 'twitter2')
      create(:subscription, user:, active: false)
      user
    end

    let!(:unconfirmed_user) do
      user = create(:user, confirmed_at: nil)
      create(:identity, user:, provider: 'twitter2')
      create(:subscription, user:, active: true)
      user
    end

    it 'returns only users who are confirmed, have a valid identity, and an active subscription' do
      expect(User.syncable).to match_array([confirmed_user_with_valid_identity_and_active_subscription,
                                            confirmed_user_with_valid_identity_and_enabled_without_subscription])
    end
  end
end

# == Schema Information
#
# Table name: identities
#
#  id                :bigint           not null, primary key
#  banner_checksum   :string
#  banner_data       :text
#  description       :string
#  handle            :string
#  image_checksum    :string
#  image_data        :text
#  provider          :string
#  sync_without_user :boolean
#  uid               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint
#
# Indexes
#
#  index_identities_on_handle   (handle) UNIQUE
#  index_identities_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Identity, type: :model do
  describe '.syncable' do
    let!(:confirmed_user_with_valid_identity_and_active_subscription) do
      user = create(:user, confirmed_at: Time.current)
      create(:identity, user: user)
      create(:subscription, user: user, active: true)
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
      create(:subscription, user: user, active: false)
      user.identity
    end

    let!(:unconfirmed_user) do
      user = create(:user, confirmed_at: nil)
      create(:identity, user: user)
      create(:subscription, user: user, active: true)
      user.identity
    end

    let!(:identity_without_user) do
      create(:identity, sync_without_user: true)
    end

    it 'returns only identities that are syncable' do
      expect(Identity.syncable).to match_array([
        confirmed_user_with_valid_identity_and_active_subscription,
        confirmed_user_with_valid_identity_and_enabled_without_subscription,
        identity_without_user
      ])
    end
  end
end

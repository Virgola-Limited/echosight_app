require 'rails_helper'

RSpec.describe Identity, type: :model do
  describe 'YAML deserialization' do
    let(:identity) { create(:identity) }

    before do
      # Create a PaperTrail version with a serialized ActiveSupport::TimeWithZone object
      identity.update(description: 'Test description')
      version = identity.versions.last
      yaml_with_time_zone = <<~YAML
        ---
        id: #{identity.id}
        description: Test description
        created_at: !ruby/object:ActiveSupport::TimeWithZone
          utc: 2024-07-15 05:32:46.841428000 Z
          zone: !ruby/object:ActiveSupport::TimeZone
            name: Etc/UTC
          time: 2024-07-15 05:32:46.841428000 Z
      YAML
      version.update_column(:object, yaml_with_time_zone)
    end

    it 'successfully deserializes ActiveSupport::TimeWithZone objects' do
      expect {
        identity.versions.last.reify
      }.not_to raise_error
    end

    it 'correctly restores the TimeWithZone object' do
      reified_identity = identity.versions.last.reify
      expect(reified_identity.created_at).to be_a(ActiveSupport::TimeWithZone)
      expect(reified_identity.created_at.to_s).to eq('2024-07-15 05:32:46 UTC')
    end
  end

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
end

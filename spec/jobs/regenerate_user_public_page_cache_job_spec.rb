require 'rails_helper'

RSpec.describe RegenerateUserPublicPageCacheJob, type: :job do
  describe '#perform' do
    let!(:identity_with_user) { create(:identity, handle: 'handle_with_user', uid: '123456') }
    let!(:identity_without_user) { create(:identity, :syncable_without_user, handle: 'handle_without_user', uid: '654321') }

    before do
      allow(Identity).to receive(:syncable).and_return([identity_with_user, identity_without_user])
      allow(PublicPageService).to receive(:new).and_call_original
      allow(Rails.cache).to receive(:fetch).and_call_original
    end

    it 'regenerates cache for identities with and without users' do
      described_class.new.perform

      identity_with_user_service = PublicPageService.new(handle: 'handle_with_user', date_range: Date.current)
      identity_without_user_service = PublicPageService.new(handle: 'handle_without_user', date_range: Date.current)

      identity_with_user_cache_key = identity_with_user_service.cache_key
      identity_without_user_cache_key = identity_without_user_service.cache_key

      expect(Rails.cache).to have_received(:fetch).with(identity_with_user_cache_key, expires_in: 24.hours).once
      expect(Rails.cache).to have_received(:fetch).with(identity_without_user_cache_key, expires_in: 24.hours).once
    end
  end
end

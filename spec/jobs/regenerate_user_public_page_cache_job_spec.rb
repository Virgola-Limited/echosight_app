require 'rails_helper'

RSpec.describe RegenerateUserPublicPageCacheJob, type: :job do
  describe '#perform' do
    let!(:identity_with_user) { create(:identity) }
    let!(:identity_without_user) { create(:identity, :syncable_without_user) }

    before do
      allow(PublicPageService).to receive(:new).and_call_original
      allow(Rails.cache).to receive(:fetch).and_call_original
    end

    it 'regenerates cache for identities with and without users' do
      expect(PublicPageService).to receive(:new).with(handle: identity_with_user.handle, current_user: identity_with_user.user, date_range: Date.current).and_call_original
      expect(PublicPageService).to receive(:new).with(handle: identity_without_user.handle, current_user: nil, date_range: Date.current).and_call_original

      described_class.new.perform

      identity_with_user_service = PublicPageService.new(handle: identity_with_user.handle, current_user: identity_with_user.user, date_range: Date.current)
      identity_without_user_service = PublicPageService.new(handle: identity_without_user.handle, current_user: nil, date_range: Date.current)

      identity_with_user_cache_key = identity_with_user_service.cache_key
      identity_without_user_cache_key = identity_without_user_service.cache_key

      expect(Rails.cache).to have_received(:fetch).with(identity_with_user_cache_key, expires_in: 24.hours)
      expect(Rails.cache).to have_received(:fetch).with(identity_without_user_cache_key, expires_in: 24.hours)
    end
  end
end

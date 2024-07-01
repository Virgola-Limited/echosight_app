class RegenerateUserPublicPageCacheJob
  include Sidekiq::Job
  include Cacheable

  def perform
    identities = Identity.syncable
    identities.each do |identity|
      regenerate_cache_for_identity(identity)
    end
  end

  private

  def regenerate_cache_for_identity(identity)
    service = PublicPageService.new(handle: identity.handle, date_range: Date.current)
    Rails.cache.fetch(service.cache_key, expires_in: 24.hours) do
      service.generate_public_page_data
    end
  end
end

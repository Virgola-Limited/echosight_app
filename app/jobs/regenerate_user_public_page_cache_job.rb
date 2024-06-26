# app/jobs/regenerate_user_public_page_cache_job.rb
class RegenerateUserPublicPageCacheJob
  include Sidekiq::Job
  include Cacheable

  def perform
    Identity.syncable.find_each do |identity|
      regenerate_cache_for_identity(identity)
    end
  end

  private

  def regenerate_cache_for_identity(identity)
    service = PublicPageService.new(handle: identity.handle, current_user: identity.user, date_range: Date.current)
    cache_key = service.cache_key_for_user_public_page(service.user, date_range: Date.current, hours: 24)
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      service.generate_public_page_data
    end
  end
end

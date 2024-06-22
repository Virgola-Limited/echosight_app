module Cacheable
  extend ActiveSupport::Concern

  def cache_key_for_user_public_page(user, date_range:, hours: 24)
    "user/#{user.id}/public_page/#{date_range}/#{Time.current.to_i / (hours.hours.to_i)}"
  end
end
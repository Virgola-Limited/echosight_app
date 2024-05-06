module Cacheable
  extend ActiveSupport::Concern


  def cache_key_for_user(user, hours: 12)
    "user/#{user.id}/public_page/#{Time.current.to_i / (hours.hours.to_i)}"
  end
end
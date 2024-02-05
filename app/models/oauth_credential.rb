class OauthCredential < ApplicationRecord
  belongs_to :identity

  def expired_or_expiring_soon?
    expires_at < Time.current + 5.minutes
  end
end

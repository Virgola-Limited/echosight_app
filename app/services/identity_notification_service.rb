# app/services/identity_notification_service.rb
class IdentityNotificationService
  def run
    identities_without_users.each do |identity|
      if has_fourteen_days_of_data?(identity)
        message = "Reach out to user if the public page is populated #{public_page_url(handle: identity.handle)}"
        PostSender.new(message: message, post_type: 'one_time', channel_type: 'slack').call
      end
    end
  end

  private

  def identities_without_users
    Identity.syncable.without_user
  end

  def has_fourteen_days_of_data?(identity)
    identity.twitter_user_metrics.count >= 14
  end

  def public_page_url(handle:)
    "https://x.com/#{handle}" # replace with the actual public page URL generation logic
  end
end

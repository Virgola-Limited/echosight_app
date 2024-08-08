# app/services/identity_notification_service.rb
class IdentityNotificationService
  include Rails.application.routes.url_helpers

  def run
    identities_without_users.each do |identity|
      if has_fourteen_days_of_data?(identity) && !notification_sent?(identity)
        message = "Reach out to user if the public page is populated #{urls(handle: identity.handle)}"
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

  def notification_sent?(identity)
    message = "Reach out to user if the public page is populated #{urls(handle: identity.handle)}"
    SentPost.exists?(message: message, post_type: 'one_time', channel_type: 'slack')
  end

  def urls(handle:)
    "https://x.com/#{handle} #{public_page_url(handle: handle)}" # replace with the actual public page URL generation logic
  end
end
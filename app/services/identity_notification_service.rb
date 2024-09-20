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
    host = Rails.application.config.action_mailer.default_url_options[:host] || 'localhost'
    port = Rails.application.config.action_mailer.default_url_options[:port]

    url = if port
      public_page_url(handle: handle, host: host, port: port)
    else
      public_page_url(handle: handle, host: host)
    end

    "https://x.com/#{handle} #{url}"
  end
end

# We've added you to Echosight, so you've already got a public page showcasing your Twitter/X analytics. Check it out and see how you stack up in the community. You can start using it fully for $5 a month.
# Let us know what you think!

#  https://app.echosight.io/p/arvidkahl

# Chris.
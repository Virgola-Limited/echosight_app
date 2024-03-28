# app/jobs/subscription_sync_job.rb
class SubscriptionSyncJob < ApplicationJob
  queue_as :default

  def perform
    Subscription.where(active: true).find_each do |subscription|
      StripeSubscriptionChecker.check_subscription(subscription)
    end
  end
end

# Handling Webhooks
# For real-time updates, you should also handle Stripe webhook events for subscription changes. Configure your application to listen for relevant events (e.g., customer.subscription.updated, customer.subscription.deleted) and use your StripeSubscriptionChecker service to update your local records in response to these events.
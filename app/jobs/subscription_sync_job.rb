# app/jobs/subscription_sync_job.rb
class SubscriptionSyncJob < ApplicationJob
  queue_as :default

  def perform
    Subscription.where(active: true).find_each do |subscription|
      StripeSubscriptionChecker.check_subscription(subscription)
    end
  end
end
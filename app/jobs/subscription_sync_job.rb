# app/jobs/subscription_sync_job.rb
class SubscriptionSyncJob
  include Sidekiq::Job

  sidekiq_options queue: :low_priority

  def perform
    Subscription.where(active: true).find_each do |subscription|
      CustomStripe::SubscriptionChecker.check_subscription(subscription)
    end
  end
end
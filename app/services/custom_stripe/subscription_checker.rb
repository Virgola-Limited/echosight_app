# app/services/stripe_subscription_checker.rb
module CustomStripe
  class SubscriptionChecker
    def self.check_subscription(subscription)
      return unless subscription.stripe_subscription_id

      stripe_sub = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
      update_local_subscription(subscription, stripe_sub)
    end

    def self.update_local_subscription(local_sub, stripe_sub)
      # Assuming you have an 'active' boolean field on your local subscriptions
      # This is a simple example; adapt it based on your actual Subscription model fields
      is_active = stripe_sub.status == 'active' && !stripe_sub.cancel_at_period_end
      local_sub.update(active: is_active)

      # Add any other fields you need to synchronize, like current_period_end, etc.
    end
  end
end
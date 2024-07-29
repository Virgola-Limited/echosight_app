module CustomStripe
  class SubscriptionChecker
    def self.check_subscription(subscription)
      return unless subscription.stripe_subscription_id

      stripe_sub = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
      update_local_subscription(subscription, stripe_sub)
    end

    def self.update_local_subscription(local_sub, stripe_sub)
      # Check if subscription status or active status have changed
      new_status = stripe_sub.status
      is_active = (stripe_sub.status == 'active' || stripe_sub.status == 'trialing') && !stripe_sub.cancel_at_period_end

      if local_sub.status != new_status || local_sub.active != is_active
        # Update only if there are changes
        local_sub.update(
          status: new_status,
          active: is_active
          # Add any other fields you need to synchronize, like current_period_end, etc.
        )
      end
    end
  end
end

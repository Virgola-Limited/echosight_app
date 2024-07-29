module CustomStripe
  class SubscriptionChecker
    def self.check_subscription(subscription)
      return unless subscription.stripe_subscription_id

      stripe_sub = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
      update_local_subscription(subscription, stripe_sub)
    end

    def self.update_local_subscription(local_sub, stripe_sub)
      # Check if subscription status has changed
      new_status = stripe_sub.status

      if local_sub.status != new_status
        # Update only if there are changes
        local_sub.update(
          status: new_status,
          current_period_end: Time.at(stripe_sub.current_period_end).to_datetime
        )
      end
    end
  end
end

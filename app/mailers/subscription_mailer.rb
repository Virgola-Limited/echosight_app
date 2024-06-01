class SubscriptionMailer < ApplicationMailer

  def subscription_confirmation(user, subscription)
    @user = user
    @subscription = subscription
    @is_transactional_email = true

    # Fetch the Stripe subscription object
    stripe_subscription = Stripe::Subscription.retrieve(@subscription.stripe_subscription_id)

    # Assign Stripe subscription object to an instance variable for the view
    @stripe_subscription = stripe_subscription

    # Retrieve the Stripe product details
    @stripe_product = Stripe::Product.retrieve(stripe_subscription.items.data.first.price.product)

    # Retrieve the latest invoice for this Stripe subscription
    @latest_invoice = Stripe::Invoice.list(customer: stripe_subscription.customer, subscription: stripe_subscription.id, limit: 1).data.first

    mail(to: @user.email, subject: 'Echosight Subscription Confirmation')
  end
end

class CreateSubscriptionService < Services::Base
  attr_reader :user, :plan_id, :stripe_token

  def initialize(user, plan_id, stripe_token)
    @user = user
    @plan_id = plan_id
    @stripe_token = stripe_token
  end

  def call
    unless plan_id.present?
      return { success: false, error: 'Please select a subscription plan.' }
    end

    begin
      customer = find_or_create_stripe_customer
      attach_payment_method(customer) if stripe_token.present?
      deactivate_existing_subscriptions
      new_subscription = create_stripe_subscription(customer)
      send_confirmation_email(new_subscription)

      { success: true, subscription: new_subscription }
    rescue => e
      ExceptionNotifier.notify_exception(e)
      { success: false, error: e.message }
    end
  end


  private

  def find_or_create_stripe_customer
    if user.stripe_customer_id.present?
      Stripe::Customer.retrieve(user.stripe_customer_id)
    else
      Stripe::Customer.create(email: user.email)
    end
  end

  def attach_payment_method(customer)
    payment_method = Stripe::PaymentMethod.create({
      type: 'card',
      card: { token: stripe_token }
    })
    Stripe::PaymentMethod.attach(payment_method.id, { customer: customer.id })
    Stripe::Customer.update(customer.id, invoice_settings: { default_payment_method: payment_method.id })
  end

  def deactivate_existing_subscriptions
    user.subscriptions.active.update_all(active: false)
  end

  def create_stripe_subscription(customer)
    stripe_subscription = Stripe::Subscription.create({
      customer: customer.id,
      items: [{ price: plan_id }],
      expand: ['latest_invoice.payment_intent']
    })

    user.subscriptions.create!(
      stripe_subscription_id: stripe_subscription.id,
      stripe_price_id: plan_id,
      active: true
    )
  end

  def send_confirmation_email(subscription)
    SubscriptionMailer.subscription_confirmation(user, subscription).deliver_later
  end
end

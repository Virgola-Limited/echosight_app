class SubscriptionsController < AuthenticatedController
  before_action :set_user_subscription, only: [:show]


  def new
    @products = Stripe::Product.list(active: true).select do |product|
      product.metadata['admin'] != 'true'
    end.map do |product|
      prices = Stripe::Price.list(product: product.id, active: true)
      OpenStruct.new(id: product.id, name: product.name, description: product.description, prices: prices.data)
    end
  end

  def show
    if @subscription.present?
      @stripe_subscription = Stripe::Subscription.retrieve(@subscription.stripe_subscription_id)

      @stripe_product = Stripe::Product.retrieve(@stripe_subscription.items.data[0].price.product)
      @stripe_invoices = Stripe::Invoice.list(customer: @stripe_subscription.customer, subscription: @subscription.stripe_subscription_id)
    end
  end

  def create
    result = CreateSubscriptionService.new(current_user, params[:plan_id], params[:stripeToken]).call
    if result[:success]
      redirect_to subscription_path, notice: 'Subscription created successfully.'
    else
      redirect_to new_subscription_path, alert: "Failed to create subscription. Please contact x@echosight.io for support. Error: #{result[:error]}"
    end
  end

  private

  def set_user_subscription
    @subscription = current_user.subscriptions.active.first
    unless @subscription
      redirect_to new_subscription_path, notice: 'Setup your subscription below to enable your public page'
    end
  end
end
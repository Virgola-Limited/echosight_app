class SubscriptionsController < AuthenticatedController
  before_action :set_user_subscription, only: [:show]


  def new
    @subscription = current_user.subscriptions.active.first

    if @subscription.present?
      redirect_to subscription_path(@subscription)
    end

    @products = Stripe::Product.list(active: true).select do |product|
      product.metadata['admin'] != 'true'
    end.map do |product|
      prices = Stripe::Price.list(product: product.id, active: true)
      OpenStruct.new(id: product.id, name: product.name, description: product.description, prices: prices.data)
    end

    @auto_select_product = @products.size == 1 && @products.first.prices.size == 1 ? @products.first : nil
  end

  def show
    unless @subscription.present?
      redirect_to new_subscription_path
    end

    @stripe_subscription = Stripe::Subscription.retrieve(@subscription.stripe_subscription_id)

    @stripe_product = Stripe::Product.retrieve(@stripe_subscription.items.data[0].price.product)
    @stripe_invoices = Stripe::Invoice.list(customer: @stripe_subscription.customer, subscription: @subscription.stripe_subscription_id)
  end

  def create
    if params[:plan_id].blank?
      redirect_to new_subscription_path, alert: "Please select a subscription plan."
      return
    end

    result = CreateSubscriptionService.new(current_user, params[:plan_id], params[:stripeToken]).call
    if result[:success]
      notice = "Subscription created successfully."
      redirect_to dashboard_index_path, notice: notice
    else
      error = result[:error] || StandardError.new("Unknown error: #{result.inspect}")
      ExceptionNotifier.notify_exception(error, data: { user: current_user, plan_id: params[:plan_id] })
      redirect_to new_subscription_path, alert: "Failed to create subscription. Please contact x@echosight.io for support."
    end
  end

  private

  def set_user_subscription
    @subscription = current_user.subscriptions.active.first
    unless @subscription
      notice = 'Setup your subscription below to enable your public page'
      trial_period_days = ENV.fetch('TRIAL_PERIOD_DAYS', 0)
      if trial_period_days.to_i.positive?
        notice = "We are currently offering a #{trial_period_days} day free trial for our early adopters. Subscribe now and pay in 90 days."
      end
      redirect_to new_subscription_path, notice: notice
    end
  end
end
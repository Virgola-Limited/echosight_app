module CustomStripe
  class EventHandler
    def call(event)
      case event.type
      when 'customer.subscription.created'
        handle_event(event.data.object, 'created')
      when 'customer.subscription.paused'
        handle_event(event.data.object, 'paused')
      when 'customer.subscription.resumed'
        handle_event(event.data.object, 'resumed')
      when 'customer.subscription.updated'
        handle_event(event.data.object, 'updated')
      when 'customer.subscription.deleted'
        handle_event(event.data.object, 'deleted')
      else
        Rails.logger.info "Unhandled event type: #{event.type}"
      end
    end

    private

    def handle_event(subscription, action)
      user = find_user(subscription)
      product_name = find_product_name(subscription)

      Notifications::SlackNotifier.call(
        message: "Subscription #{action}: Product: #{product_name}, User: #{user&.email}"
      )

      # update_user_subscription(user, subscription, action) if user && %w[updated deleted].include?(action)
    end

    def find_user(subscription)
      Subscription.find_by(stripe_subscription_id: subscription.id)&.user
    end

    def find_product_name(subscription)
      item = subscription.items.data.first
      price = Stripe::Price.retrieve(item.price.id)
      product = Stripe::Product.retrieve(price.product)
      product.name
    rescue StandardError => e
      Rails.logger.error "Error fetching product name: #{e.message}"
      "Unknown Product"
    end

    # def update_user_subscription(user, subscription, action)
    #   user_subscription = user.subscriptions.find_by(stripe_subscription_id: subscription.id)
    #   if action == 'updated'
    #     user_subscription.update(
    #       status: subscription.status,
    #       current_period_end: Time.at(subscription.current_period_end).to_datetime
    #     )
    #   elsif action == 'deleted'
    #     user_subscription.update(status: 'canceled')
    #   end
    # end
  end
end

module CustomStripe
  class EventHandler
    def call(event)
      Rails.logger.info "Processing event: #{event.type}"
      Rails.logger.info "Event object: #{event.data.object.to_json}"

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

      message = "Subscription #{action}: Product: #{product_name}, User: #{user&.email}"
      if action == 'created'
        message += ", Follow this user: https://x.com/#{user&.handle}"
      end
      Notifications::SlackNotifier.call(
        message: message
      )

      update_user_subscription(user, subscription, action) if user && %w[created updated resumed deleted].include?(action)
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

    def update_user_subscription(user, subscription, action)
      user_subscription = user.subscriptions.find_by(stripe_subscription_id: subscription.id)
      if user_subscription
        is_active = (subscription.status == 'active' || subscription.status == 'trialing') && !subscription.cancel_at_period_end
        if %w[created updated resumed].include?(action)
          user_subscription.update(
            status: subscription.status,
            active: is_active,
            current_period_end: Time.at(subscription.current_period_end).to_datetime
          )
        elsif action == 'deleted'
          # review this code.. looks odd.
          user_subscription.update(status: subscription.status, active: false, current_period_end: Time.at(subscription.current_period_end).to_datetime)
        end
      end
    end
  end
end

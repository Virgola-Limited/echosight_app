module CustomStripe
  class EventHandler
    def call(event)
      Rails.logger.info "Processing event: #{event.type}"
      Rails.logger.info "Event object: #{event.data.object.to_json}"

      # Send full event information to Slack
      send_full_event_to_slack(event)

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

    def send_full_event_to_slack(event)
      message = "Received Stripe event: #{event.type}\n" \
                "Event ID: #{event.id}\n" \
                "Event Object: #{event.data.object.to_json}"

      Notifications::SlackNotifier.call(
        message: message,
        channel: :stripe
      )
    end

    def handle_event(subscription, action)
      user = find_user(subscription)
      product_name = find_product_name(subscription)

      message = "Subscription #{action}: Product: #{product_name}, User: #{user&.email}"
      if action == 'created'
        message += ", Follow this user: https://x.com/#{user&.handle}"
      end
      Notifications::SlackNotifier.call(
        message: message,
        channel: :general
      )

      unless update_user_subscription(user, subscription, action)
        error_message = "Failed to find user subscription for Stripe ID #{subscription.id}"
        Notifications::SlackNotifier.call(
          message: error_message,
          channel: :errors
        )
      end
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
      return false unless user

      user_subscription = user.subscriptions.find_by(stripe_subscription_id: subscription.id)
      return false unless user_subscription

      user_subscription.update(
        status: subscription.status,
        current_period_end: Time.at(subscription.current_period_end).to_datetime
      )
      true
    end
  end
end

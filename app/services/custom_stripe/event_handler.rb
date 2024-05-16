module CustomStripe
  class EventHandler
    def call(event)
      case event.type
        when 'customer.subscription.created'
          handle_subscription_created(event.data.object)
        when 'customer.subscription.paused'
          handle_subscription_paused(event.data.object)
        when 'customer.subscription.resumed'
          handle_subscription_resumed(event.data.object)
        when 'customer.subscription.updated'
          handle_subscription_updated(event.data.object)
        when 'customer.subscription.deleted'
          handle_subscription_deleted(event.data.object)
        else
          Rails.logger.info "Unhandled event type: #{event.type}"
        end
    end

    private

    def handle_subscription_updated(subscription)
      Notifications::SlackNotifier.call(
        message: "Subscription updated: #{subscription.inspect}"
      )
      # user = User.find_by(stripe_subscription_id: subscription.id)
      # return unless user

      # user.update(
      #   stripe_status: subscription.status,
      #   current_period_end: Time.at(subscription.current_period_end).to_datetime
      # )
    end

    def handle_subscription_deleted(subscription)
      Notifications::SlackNotifier.call(
        message: "Subscription deleted: #{subscription.inspect}"
      )
      # user = User.find_by(stripe_subscription_id: subscription.id)
      # return unless user

      # user.update(stripe_status: 'canceled')
    end

    def handle_subscription_resumed(subscription)
      Notifications::SlackNotifier.call(
        message: "Subscription resumed: #{subscription.inspect}"
      )
    end

    def handle_subscription_paused(subscription)
      Notifications::SlackNotifier.call(
        message: "Subscription paused: #{subscription.inspect}"
      )
    end

    def handle_subscription_created(subscription)
      Notifications::SlackNotifier.call(
        message: "Subscription created: #{subscription.inspect}"
      )
    end
  end
end

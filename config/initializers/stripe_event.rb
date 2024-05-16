require Rails.root.join('app/services/custom_stripe/event_handler')

StripeEvent.configure do |events|
  events.subscribe 'customer.subscription.created', ::CustomStripe::EventHandler.new
  events.subscribe 'customer.subscription.updated', ::CustomStripe::EventHandler.new
  events.subscribe 'customer.subscription.deleted', ::CustomStripe::EventHandler.new
  events.subscribe 'customer.subscription.paused', ::CustomStripe::EventHandler.new
  events.subscribe 'customer.subscription.resumed', ::CustomStripe::EventHandler.new
end
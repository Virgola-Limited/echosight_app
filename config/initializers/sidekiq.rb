# config/initializers/sidekiq.rb
require 'sidekiq'

# Define your custom middleware class directly under the Sidekiq module
module Sidekiq
  class ExceptionNotificationMiddleware
    def call(worker, msg, queue)
      begin
        yield
      rescue => exception
        ExceptionNotifier.notify_exception(exception, data: { sidekiq: msg })
        raise exception
      end
    end
  end
end

Sidekiq.configure_server do |config|
  # Add your custom middleware to the Sidekiq server middleware chain
  config.server_middleware do |chain|
    chain.add Sidekiq::ExceptionNotificationMiddleware
  end
end

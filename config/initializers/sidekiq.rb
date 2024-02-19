# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.logger.level = Logger::DEBUG

if !Rails.env.development? && !Rails.env.test?
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

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!([
      {
        'name'  => 'Update Twitter Data - every hour',
        'cron'  => '0 */12 * * *', # Runs at the start of every 12th hour
        'class' => 'UpdateTwitterDataJob'
        # Specify other job properties if needed
      }
      # Add more jobs here if needed
    ])
  end
end

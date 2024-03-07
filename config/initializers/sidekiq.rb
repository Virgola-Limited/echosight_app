# frozen_string_literal: true

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.logger.level = Logger::DEBUG

if !Rails.env.development? && !Rails.env.test?
  module Sidekiq
    class ExceptionNotificationMiddleware
      def call(_worker, msg, _queue)
        yield
      rescue StandardError => e
        ExceptionNotifier.notify_exception(e, data: { sidekiq: msg })
        raise e
      end
    end
  end

  Sidekiq.configure_server do |config|
    # Add your custom middleware to the Sidekiq server middleware chain
    config.server_middleware do |chain|
      chain.add Sidekiq::ExceptionNotificationMiddleware
    end

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!(
      [
        {
          'name' => 'Fetch Tweets - every 7am UTC',
          'cron' => '0 7, * * * *',
          'class' => 'Twitter::TweetsFetcherJob'
        }
      ]
    )
  end
end

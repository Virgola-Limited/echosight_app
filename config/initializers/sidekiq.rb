# frozen_string_literal: true

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'
require_relative './application_constants'
require_relative '../../lib/cron_expression_generator'

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

    # SSL verification mode configuration for Redis
    config.redis = {
      url: ENV['REDIS_URL'], # Assuming you have your Redis URL in this ENV var
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    }

    Sidekiq::Cron::Job.destroy_all!

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!(
      [
        {
          'name' => 'Fetch Tweets',
          'cron' => CronExpressionGenerator.for_interval(ApplicationConstants::TWITTER_FETCH_INTERVAL),
          'class' => 'Twitter::TweetsFetcherJob'
        },
      ]
    )
  end
end

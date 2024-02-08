# config/initializers/sidekiq.rb
require 'sidekiq'

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
  end
end

if ENV.fetch("IS_SCHEDULER", "false") == "true"
  Sidekiq.configure_server do |config|
    schedule_file = "config/sidekiq.yml"
    if File.exist?(schedule_file) && Sidekiq.server?
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    end
  end
end
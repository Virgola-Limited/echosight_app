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

if ENV.fetch("IS_SCHEDULER", false)
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(File.expand_path("../scheduler.yml", File.dirname(__FILE__)))
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end
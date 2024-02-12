# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-scheduler'

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

    # Enable dynamic schedules
    Sidekiq::Scheduler.dynamic = true

    # Load the schedule from YAML file only if this is the scheduler instance
    if ENV.fetch("IS_SCHEDULER", false)
      config.on(:startup) do
        schedule_file = File.expand_path("../scheduler.yml", File.dirname(__FILE__))
        if File.exist?(schedule_file) && Sidekiq::Scheduler.dynamic
          Sidekiq.schedule = YAML.load_file(schedule_file)
          Sidekiq::Scheduler.reload_schedule!
        else
          Sidekiq.logger.warn "No sidekiq schedule file at #{schedule_file} or not on dynamic mode."
        end
      end
    end
  end
end

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'
require 'sidekiq-unique-jobs'
require 'erb'

Sidekiq.logger.level = Logger::DEBUG

SidekiqUniqueJobs.configure do |config|
  config.logger = Sidekiq.logger
  config.debug_lua = true
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    connect_timeout: 2,
    read_timeout: 2,
    write_timeout: 2
  }

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.on(:startup) do
    schedule_file = "config/sidekiq_schedule.yml"
    if File.exist?(schedule_file)
      Sidekiq::Cron::Job.destroy_all!
      schedule = YAML.load(ERB.new(File.read(schedule_file)).result)
      Sidekiq::Cron::Job.load_from_hash(schedule)
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    connect_timeout: 2,
    read_timeout: 2,
    write_timeout: 2
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

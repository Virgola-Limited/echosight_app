# Basic application health check
OkComputer::Registry.register "app", OkComputer::AppVersionCheck.new

# Critical checks (e.g., PostgreSQL)
OkComputer::Registry.register "postgresql", OkComputer::ActiveRecordCheck.new

# Additional checks (e.g., Redis and Sidekiq)
OkComputer::Registry.register "redis", OkComputer::RedisCheck.new(Redis.new(url: ENV['REDIS_URL']))
OkComputer::Registry.register "sidekiq", OkComputer::SidekiqLatencyCheck.new('default', 100)

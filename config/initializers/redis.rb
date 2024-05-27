# config/initializers/redis.rb

$redis = Redis.new(
  url: ENV["REDIS_URL"],
  ssl_params: {
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  },
  connect_timeout: 2,   # Default is 1 second
  read_timeout: 2,      # Default is 1 second
  write_timeout: 2      # Default is 1 second
)

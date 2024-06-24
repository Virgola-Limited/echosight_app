# Fetch the thread count from the environment or default to 5
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Set the worker count based on the environment
worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 2 })  # Default to 2 workers
workers worker_count if worker_count > 1

# Preload the application before forking workers
preload_app!

# Adjust the worker timeout for development
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Set the port for Puma to listen on
port ENV.fetch("PORT") { 3000 }

# Set the environment for Puma
environment ENV.fetch("RAILS_ENV") { "development" }

# Set the pidfile location
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow Puma to be restarted by `bin/rails restart` command
plugin :tmp_restart

on_worker_boot do
  # Ensure ActiveRecord connections are reestablished
  ActiveRecord::Base.establish_connection
end

before_fork do
  # Additional garbage collection settings
  GC.start
end

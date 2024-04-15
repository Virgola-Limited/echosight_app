# Use this file to easily define all of your cron jobs in development (whenever gem).
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

every 6.hour do
  # Not finished in development ideally it mimics sidekiq.yml if we have the API bandwidth
end

# Learn more: http://github.com/javan/whenever

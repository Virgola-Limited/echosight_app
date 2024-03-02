# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

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

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!(
  [
    {
      'name'  => 'Update Twitter Followers - daily',
      'cron'  => '0 8 * * *',
      'class' => 'Twitter::FollowersUpdaterJob'
    },
    {
      'name'  => 'Refresh Tweet Metrics at 8am UTC',
      'cron'  => '0 8 * * *',
      'class' => 'Twitter::TweetMetricsRefresherJob'
    },
    {
      'name'  => 'Refresh Tweet Metrics at 8pm UTC',
      'cron'  => '0 16 * * *',
      'class' => 'Twitter::TweetMetricsRefresherJob'
    },
    {
      'name'  => 'Fetch New Tweets - every 12 hours',
      'cron'  => '0 8,20 * * *',
      'class' => 'Twitter::NewTweetsFetcherJob'
    },
    # {
    #   'name'  => 'Send Daily Application Rate Limit levels to Slack',
    #   'cron'  => '0 0 * * *',
    #   'class' => 'Twitter::SendRateLimitsToSlackJob'
    # }
    ])
  end
end

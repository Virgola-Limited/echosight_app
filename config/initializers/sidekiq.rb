# frozen_string_literal: true

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'

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

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!(
      [
        {
          'name' => 'Fetch Tweets - every 7am UTC',
          'cron' => '0 7, * * * *',
          'class' => 'Twitter::TweetsFetcherJob',
          'args' => ['SocialData::ClientAdapter']
        }
        # {
        #   'name'  => 'Update Twitter Followers - daily',
        #   'cron'  => '0 8 * * *',
        #   'class' => 'Twitter::FollowersUpdaterJob',
        #   'args'  => ['SocialData::ClientAdapter']
        # },
        # {
        #   'name'  => 'Fetch New Tweets - every 7am UTC',
        #   'cron'  => '0 7, * * * *',
        #   'class' => 'Twitter::NewTweetsFetcherJob',
        #   'args'  => ['SocialData::ClientAdapter']
        # },
        # {
        #   'name'  => 'Refresh Tweet Metrics at 8am UTC',
        #   'cron'  => '0 8 * * *',
        #   'class' => 'Twitter::TweetMetricsRefresherJob',
        #   'args'  => ['SocialData::ClientAdapter']
        # },
        # {
        #   'name'  => 'Refresh Tweet Metrics at 8pm UTC',
        #   'cron'  => '0 16 * * *',
        #   'class' => 'Twitter::TweetMetricsRefresherJob',
        #   'args'  => ['SocialData::ClientAdapter']
        # },
        # {
        #   'name'  => 'Send Daily Application Rate Limit levels to Slack',
        #   'cron'  => '0 0 * * *',
        #   'class' => 'Twitter::SendRateLimitsToSlackJob'
        # }
      ]
    )
  end
end

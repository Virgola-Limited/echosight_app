# frozen_string_literal: true

# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'
require_relative '../../lib/cron_expression_generator'

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

  Sidekiq.configure_client do |config|
    config.redis = {
      url: ENV["REDIS_URL"],
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
      connect_timeout: 2,   # Default is 1 second
      read_timeout: 2,      # Default is 1 second
      write_timeout: 2      # Default is 1 second
    }
  end

  Sidekiq.configure_server do |config|
    # Add your custom middleware to the Sidekiq server middleware chain
    config.server_middleware do |chain|
      chain.add Sidekiq::ExceptionNotificationMiddleware
    end

    config.redis = {
      url: ENV["REDIS_URL"],
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
      connect_timeout: 2,   # Default is 1 second
      read_timeout: 2,      # Default is 1 second
      write_timeout: 2      # Default is 1 second
    }

    Sidekiq::Cron::Job.destroy_all!

    # Define your Sidekiq-Cron jobs here
    Sidekiq::Cron::Job.load_from_array!(
      [
        {
          'name' => 'Fetch Tweets',
          'cron' => CronExpressionGenerator.for_interval(ApplicationConstants::TWITTER_FETCH_INTERVAL),
          'class' => 'Twitter::TweetsFetcherJob'
        },
        {
          'name' => 'Sync Subscriptions - every 1 hour',
          'cron' => '0 * * * *',
          'class' => 'SubscriptionSyncJob'
        },
        {
          'name' => 'Regenerate User Public Page Cache - every 3 hours',
          'cron' => '0 */3 * * *',
          'class' => 'RegenerateUserPublicPageCacheJob'
        },
        {
          'name' => 'Users Without Subscription Email - every 1 day',
          'cron' => '0 0 * * *',
          'class' => 'UsersWithoutSubscriptionEmailJob'
        },
        {
          'name' => 'capture_leaderboard_job',
          'cron' => '0 * * * *',
          'class' => 'Twitter::CaptureLeaderboardJob'
        }
        # Not needed in OAuth1
        # {
        #   'name' => 'Refresh OAuth Credentials - every 30 minutes',
        #   'cron' => '*/30 * * * *',
        #   'class' => 'Twitter::RefreshOauthCredentialsJob'
        # },
        # {
        #   'name' => 'Remove old empty ApiBatches',
        #   'cron' => '0 0 * * *',
        #   'class' => 'RemoveOldEmptyApiBatchJob'
        # }
      ]
    )
  end
end

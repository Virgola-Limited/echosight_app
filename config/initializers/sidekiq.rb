# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-cron'
require_relative '../../lib/cron_expression_generator'

Sidekiq.logger.level = Logger::DEBUG

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    connect_timeout: 2,   # Default is 1 second
    read_timeout: 2,      # Default is 1 second
    write_timeout: 2      # Default is 1 second
  }

  # Use Sidekiq's built-in error handler
  # if Rails.application.credentials.dig(:notify_exceptions)
  #   config.error_handlers << proc { |ex, ctx_hash| ExceptionNotifier.notify_exception(ex, data: ctx_hash) }
  # end

  Sidekiq::Cron::Job.destroy_all!

  Sidekiq::Cron::Job.load_from_array!(
    [
        {
          'name' => 'Queue Monitor - every 5 minutes',
          'cron' => '*/5 * * * *',
          'class' => 'QueueMonitorJob'
        },
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
        },
        {
          'name' => 'identity_notifications_job',
          'cron' => "0 10 * * *",
          'class' => 'IdentityNotificationJob',
          'tz' => "Australia/Sydney"
        }
      ]
    )
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

        # {
        #   'name' => 'Remove old empty ApiBatches',
        #   'cron' => '0 0 * * *',
        #   'class' => 'RemoveOldEmptyApiBatchJob'
        # }
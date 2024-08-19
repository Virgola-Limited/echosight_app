require 'sidekiq'
require 'sidekiq-cron'
require_relative '../../lib/cron_expression_generator'

Sidekiq.logger.level = Logger::DEBUG

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    connect_timeout: 2,
    read_timeout: 2,
    write_timeout: 2
  }

  config.client_middleware do |chain|
    # Add any client middleware here if needed
  end

  config.server_middleware do |chain|
    # Add any server middleware here if needed
  end

  Sidekiq::Cron::Job.destroy_all!
  unless ENV['DISABLE_SIDEKIQ_CRON']
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
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    connect_timeout: 2,
    read_timeout: 2,
    write_timeout: 2
  }
end

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'exception_notification/rails'

module EchosightApp
  class Application < Rails::Application
    config.action_view.default_form_builder = 'CustomFormBuilder'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    # config.generators.system_tests = nil
    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.helper false
      g.assets false
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
      g.controller_specs false
    end

    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/app/components)
    config.action_mailer.preview_paths << "#{Rails.root}/lib/mailer_previews"

    config.action_mailer.asset_host = Rails.application.credentials.dig(:asset_host) || 'https://app.echosight.io'

    console do
      puts 'Helpful commands:'
      puts 'Twitter::TweetsFetcherJob.new.perform'
      puts 'Twitter::TweetsFetcher.new(user: User.first).call'
    end

    config.action_mailer.default_url_options = {
      host: ENV["MAILER_HOST"] || Rails.application.credentials.dig(:host) || 'localhost',
      port: ENV["MAILER_PORT"]
    }

    # Delivery method
    config.action_mailer.delivery_method = :smtp

    # SMTP settings with fallbacks for development
    config.action_mailer.smtp_settings = {
      address: Rails.application.credentials.dig(:email, :address),
      port: Rails.application.credentials.dig(:email, :port),
      user_name: Rails.application.credentials.dig(:email, :user_name),
      password: Rails.application.credentials.dig(:email, :password),
      authentication: :plain,
      ssl: ENV['SMTP_SETTINGS_SSL'] == 'true',
      enable_starttls_auto: ENV['SMTP_SETTINGS_ENABLE_STARTTLS_AUTO'] == 'true'
    }
    # Raise delivery errors only in development
    config.action_mailer.raise_delivery_errors = Rails.env.development?
  end
end

require 'platform-api'

namespace :db do
  desc "Import production database to staging"
  task import_production_to_staging: :environment do
    production_app = 'your-production-app'
    staging_app = 'your-staging-app'
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_API_KEY'])

    # Enable maintenance mode on staging
    begin
      heroku.app.update(staging_app, { 'maintenance' => true })
    rescue Excon::Error::NotFound
      puts "Failed to enable maintenance mode on staging"
      exit
    end

    # Capture latest backup from production
    heroku.postgres.backup.capture(production_app)

    # Get the latest backup URL
    latest_backup = heroku.postgres.backup.list(production_app).first
    latest_backup_url = heroku.postgres.backup.url(production_app, latest_backup['name'])['url']

    # Reset and restore the staging database
    begin
      heroku.postgres.reset(staging_app, 'DATABASE_URL')
      heroku.postgres.backup.restore(latest_backup_url, 'DATABASE_URL', staging_app)
    rescue Excon::Error::NotFound
      puts "Failed to reset or restore the staging database"
      exit
    end

    # Disable maintenance mode on staging
    begin
      heroku.app.update(staging_app, { 'maintenance' => false })
    rescue Excon::Error::NotFound
      puts "Failed to disable maintenance mode on staging"
      exit
    end
  end
end

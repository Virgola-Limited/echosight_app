namespace :db do
  desc "Import production database to staging"
  task import_production_to_staging: :environment do
    production_app = 'echosight-productoin'
    staging_app = 'echosight-staging'

    # Enable maintenance mode on staging
    system("heroku maintenance:on --app #{staging_app}")

    # Capture latest backup from production
    system("heroku pg:backups capture --app #{production_app}")
    latest_backup_url = `heroku pg:backups:url --app #{production_app}`.strip

    # Download the latest backup
    system("curl -o latest.dump '#{latest_backup_url}'")

    # Reset and restore the staging database
    system("heroku pg:reset DATABASE --confirm #{staging_app} --app #{staging_app}")
    system("heroku pg:backups:restore 'latest.dump' DATABASE_URL --app #{staging_app} --confirm #{staging_app}")

    # Remove the downloaded backup
    system("rm latest.dump")

    # Disable maintenance mode on staging
    system("heroku maintenance:off --app #{staging_app}")
  end
end

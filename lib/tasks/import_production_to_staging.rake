namespace :db do
  desc "Import production database to staging"
  task import_production_to_staging: :environment do
    production_app = 'your-production-app'
    staging_app = 'your-staging-app'

    system("heroku pg:backups capture --app #{production_app}")
    latest_backup_url = `heroku pg:backups:url --app #{production_app}`.strip
    system("curl -o latest.dump '#{latest_backup_url}'")
    system("heroku pg:reset DATABASE --confirm #{staging_app} --app #{staging_app}")
    system("heroku pg:backups:restore 'latest.dump' DATABASE_URL --app #{staging_app} --confirm #{staging_app}")
    system("rm latest.dump")
  end
end


# 2024-06-17 21:33:43 UTC
# 2024-06-17 21:33:57 UTC
# 2024-06-17 21:34:19 UTC
# 2024-06-17 21:34:30 UTC
# 2024-06-17 21:34:40 UTC
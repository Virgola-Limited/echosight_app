#!/bin/bash

# Check if USE_EXISTING_DUMP is set to true
if [ "$USE_EXISTING_DUMP" != "true" ]; then
  # Ensure we are starting fresh
  [ -e latest.dump ] && rm latest.dump

  # Capture and download the backup from Heroku (only if you haven't already done this)
  heroku pg:backups:capture -a echosight-production
  heroku pg:backups:download -a echosight-production
fi

# Drop and recreate the development database
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rails db:drop
rails db:create

# Restore the backup to the development database
pg_restore --no-owner -d echosight_app_development latest.dump

# Run any pending migrations
rails db:migrate
ruby ../lib/fetch_images.rb

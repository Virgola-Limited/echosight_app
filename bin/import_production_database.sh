
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Set your Render API key and service ID
RENDER_API_KEY="xxx"
RENDER_SERVICE_ID="xxx"


# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists jq; then
  echo "Error: jq is not installed. Please install it and try again."
  echo "On macOS, you can install it with: brew install jq"
  echo "On Ubuntu, you can install it with: sudo apt-get install jq"
  exit 1
fi

if ! command_exists curl; then
  echo "Error: curl is not installed. Please install it and try again."
  exit 1
fi

# Check if USE_EXISTING_DUMP is set to true
if [ "$USE_EXISTING_DUMP" != "true" ]; then
  # Ensure we are starting fresh
  [ -e latest.dump ] && rm latest.dump

  echo "Fetching latest backup URL from Render..."
  # Get the latest backup URL from Render
  API_RESPONSE=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "https://api.render.com/v1/services/$RENDER_SERVICE_ID/backups")

  echo "API Response:"
  echo "$API_RESPONSE"

  # Check if the response is valid JSON
  if ! echo "$API_RESPONSE" | jq empty > /dev/null 2>&1; then
    echo "Error: Invalid JSON response from Render API."
    exit 1
  fi

  # Try to extract the backup URL
  BACKUP_URL=$(echo "$API_RESPONSE" | jq -r '.[0].url // empty')

  if [ -z "$BACKUP_URL" ]; then
    echo "Error: Failed to retrieve backup URL from Render. Please check your API key and service ID."
    exit 1
  fi

  echo "Downloading backup from Render..."
  # Download the backup
  if ! curl -o latest.dump "$BACKUP_URL"; then
    echo "Error: Failed to download the backup from Render."
    exit 1
  fi
fi

if [ ! -f latest.dump ]; then
  echo "Error: latest.dump file not found. Make sure the download was successful or USE_EXISTING_DUMP is set correctly."
  exit 1
fi

echo "Dropping and recreating the development database..."
# Drop and recreate the development database
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rails db:drop
rails db:create

echo "Restoring the backup to the development database..."
# Restore the backup to the development database
if ! pg_restore --no-owner -d echosight_app_development latest.dump; then
  echo "Warning: pg_restore completed with some errors. This is often normal, but please check the output above."
fi

echo "Running pending migrations..."
# Run any pending migrations
rails db:migrate

echo "Fetching images..."
ruby ../lib/fetch_images.rb

echo "Database import completed successfully!"
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Check for required environment variables
if [ -z "$RENDER_API_KEY" ]; then
    echo "Error: RENDER_API_KEY environment variable is not set."
    exit 1
fi

if [ -z "$RENDER_DATABASE_ID" ]; then
    echo "Error: RENDER_DATABASE_ID environment variable is not set."
    echo "Please set this to your database ID, which can be found in the URL of your database in the Render dashboard."
    echo "Example: For URL https://dashboard.render.com/d/dpg-cquognbv2p9s73e4gsj0-a, the ID is dpg-cquognbv2p9s73e4gsj0-a"
    exit 1
fi

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

  API_URL="https://api.render.com/v1/backups?limit=1"
  echo "Fetching latest backup URL from Render..."
  echo "API URL: $API_URL"

  # Get the latest backup URL from Render
  API_RESPONSE=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" "$API_URL")

  echo "API Response:"
  echo "$API_RESPONSE"

  # Check if the response is valid JSON
  if ! echo "$API_RESPONSE" | jq empty > /dev/null 2>&1; then
    echo "Error: Invalid JSON response from Render API."
    echo "Please check your API key and ensure you have the correct permissions."
    echo "API Key (first 4 characters): ${RENDER_API_KEY:0:4}..."
    echo "If the issue persists, please contact Render support for assistance with API access."
    exit 1
  fi

  # Try to extract the backup URL
  BACKUP_URL=$(echo "$API_RESPONSE" | jq -r '.results[0].url // empty')

  if [ -z "$BACKUP_URL" ]; then
    echo "Error: Failed to retrieve backup URL from Render."
    echo "API Response:"
    echo "$API_RESPONSE" | jq '.'
    echo "If the response is empty, ensure that you have backups enabled for your database and that at least one backup exists."
    exit 1
  fi

  echo "Backup URL: $BACKUP_URL"

  echo "Downloading backup from Render..."
  # Download the backup
  if ! curl -L -o latest.dump "$BACKUP_URL"; then
    echo "Error: Failed to download the backup from Render."
    echo "Please check your network connection and try again."
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
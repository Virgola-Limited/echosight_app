#!/bin/bash

# Ensure the RAILS_ENV variable is set, default to production if not provided
RAILS_ENV=${RAILS_ENV:-production}

# Run the build commands
bundle install
yarn install
bundle exec rake db:migrate
bin/rails assets:precompile
bin/vite build

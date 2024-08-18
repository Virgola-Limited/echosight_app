#!/usr/bin/env bash
set -o errexit
set -x  # Enable debugging

echo "==== Build Environment ===="
echo "PWD: $PWD"
echo "HOME: $HOME"

# Install jemalloc using apt
sudo apt-get update
sudo apt-get install -y libjemalloc2

# Find the installed jemalloc library
JEMALLOC_PATH=$(find /usr/lib -name "libjemalloc.so*" | head -n 1)

echo "jemalloc installed at: $JEMALLOC_PATH"

# Set up environment variables
echo "Setting up LD_PRELOAD and LD_LIBRARY_PATH"
export LD_PRELOAD="$JEMALLOC_PATH"
export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"

echo "LD_PRELOAD is now set to: $LD_PRELOAD"
echo "LD_LIBRARY_PATH is now set to: $LD_LIBRARY_PATH"

# Create a script to set environment variables
cat << EOF > $PWD/set_jemalloc_env.sh
export LD_PRELOAD="$JEMALLOC_PATH"
export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
EOF

echo "Created set_jemalloc_env.sh script:"
cat $PWD/set_jemalloc_env.sh

# Run the rest of your build process
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile

echo "==== Verifying jemalloc installation ===="
ls -l $JEMALLOC_PATH
file $JEMALLOC_PATH
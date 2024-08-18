#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -x  # Enable debugging

echo "==== Build Environment ===="
echo "PWD: $PWD"
echo "HOME: $HOME"

# Install jemalloc using apt
if ! sudo apt-get update; then
    echo "Failed to update apt. Continuing without jemalloc."
else
    if ! sudo apt-get install -y libjemalloc2; then
        echo "Failed to install jemalloc. Continuing without it."
    else
        echo "jemalloc installed successfully."
    fi
fi

# Find the installed jemalloc library
JEMALLOC_PATH=$(find /usr/lib /usr/lib/x86_64-linux-gnu -name "libjemalloc.so*" | head -n 1)

if [ -z "$JEMALLOC_PATH" ]; then
    echo "jemalloc library not found. Continuing without it."
else
    echo "jemalloc installed at: $JEMALLOC_PATH"

    # Create a script to set environment variables
    cat << EOF > $PWD/set_jemalloc_env.sh
#!/bin/bash
export LD_PRELOAD="${LD_PRELOAD:-$JEMALLOC_PATH}"
if [[ ":$LD_LIBRARY_PATH:" != *":/usr/lib:"* ]]; then
    export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
fi
if [[ ":$LD_LIBRARY_PATH:" != *":/usr/lib/x86_64-linux-gnu:"* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
fi
echo "LD_PRELOAD is set to: $LD_PRELOAD"
echo "LD_LIBRARY_PATH is set to: $LD_LIBRARY_PATH"
EOF

    chmod +x $PWD/set_jemalloc_env.sh
    echo "Created set_jemalloc_env.sh script:"
    cat $PWD/set_jemalloc_env.sh
fi

# Run the rest of your build process
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile

echo "==== Verifying jemalloc installation ===="
if [ -n "$JEMALLOC_PATH" ]; then
    ls -l $JEMALLOC_PATH
    file $JEMALLOC_PATH
else
    echo "jemalloc not installed."
fi

echo "==== Current Environment Variables ===="
env | grep LD_
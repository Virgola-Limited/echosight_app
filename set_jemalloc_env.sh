#!/bin/bash

# Use the environment variable if set, otherwise use the default path
export LD_PRELOAD="${LD_PRELOAD:-/usr/lib/x86_64-linux-gnu/libjemalloc.so.2}"

# Append to LD_LIBRARY_PATH if not already included
if [[ ":$LD_LIBRARY_PATH:" != *":/usr/lib:"* ]]; then
    export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
fi
if [[ ":$LD_LIBRARY_PATH:" != *":/usr/lib/x86_64-linux-gnu:"* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
fi

echo "LD_PRELOAD is set to: $LD_PRELOAD"
echo "LD_LIBRARY_PATH is set to: $LD_LIBRARY_PATH"
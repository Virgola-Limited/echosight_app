#!/usr/bin/env bash
set -o errexit
set -x  # Enable debugging

echo "==== Build Environment ===="
echo "PWD: $PWD"
echo "HOME: $HOME"
echo "RENDER_PROJECT_DIR: $RENDER_PROJECT_DIR"

# Install jemalloc in the project directory
JEMALLOC_VERSION=5.3.0
JEMALLOC_DIR="$PWD/jemalloc"

echo "Installing jemalloc in $JEMALLOC_DIR..."
mkdir -p $JEMALLOC_DIR
curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf - -C $JEMALLOC_DIR --strip-components=1
cd $JEMALLOC_DIR
./configure --prefix=$JEMALLOC_DIR
make
make install
echo "jemalloc installation completed in $JEMALLOC_DIR"

echo "Verifying installation:"
ls -l $JEMALLOC_DIR/lib
file $JEMALLOC_DIR/lib/libjemalloc.so

echo "Setting up LD_PRELOAD and LD_LIBRARY_PATH"
export LD_PRELOAD="$JEMALLOC_DIR/lib/libjemalloc.so"
export LD_LIBRARY_PATH="$JEMALLOC_DIR/lib:$LD_LIBRARY_PATH"

echo "LD_PRELOAD is now set to: $LD_PRELOAD"
echo "LD_LIBRARY_PATH is now set to: $LD_LIBRARY_PATH"

# Run the rest of your build process
cd $PWD
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile

echo "==== Final Build Directory Structure ===="
ls -R $PWD/jemalloc

# Create a script to set environment variables
cat << EOF > set_jemalloc_env.sh
export LD_PRELOAD="$JEMALLOC_DIR/lib/libjemalloc.so"
export LD_LIBRARY_PATH="$JEMALLOC_DIR/lib:$LD_LIBRARY_PATH"
EOF

echo "Created set_jemalloc_env.sh script"
cat set_jemalloc_env.sh
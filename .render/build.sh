#!/usr/bin/env bash
set -o errexit

# Install jemalloc in a persistent directory
JEMALLOC_VERSION=5.3.0
JEMALLOC_DIR=$PWD/jemalloc

echo "Current working directory: $PWD"
echo "JEMALLOC_DIR: $JEMALLOC_DIR"

if [ ! -d "$JEMALLOC_DIR" ]; then
  echo "Installing jemalloc..."
  mkdir -p $JEMALLOC_DIR
  curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf - -C $JEMALLOC_DIR --strip-components=1
  cd $JEMALLOC_DIR
  ./configure --prefix=$JEMALLOC_DIR
  make
  make install
  echo "jemalloc installation completed"
else
  echo "jemalloc already installed"
fi

# Print the location of libjemalloc.so for verification
JEMALLOC_LIB="$JEMALLOC_DIR/lib/libjemalloc.so"
echo "Expected libjemalloc.so location: $JEMALLOC_LIB"

if [ -f "$JEMALLOC_LIB" ]; then
  echo "libjemalloc.so exists at the expected location"
else
  echo "ERROR: libjemalloc.so not found at the expected location"
fi

echo "Please set LD_PRELOAD to this path in your Render dashboard: $JEMALLOC_LIB"

# Run the rest of your build process
cd $HOME/project/src  # Adjust this path if necessary
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile
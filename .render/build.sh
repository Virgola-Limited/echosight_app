#!/usr/bin/env bash
set -o errexit

# Install jemalloc in a persistent directory
JEMALLOC_VERSION=5.3.0
JEMALLOC_DIR=$PWD/jemalloc

if [ ! -d "$JEMALLOC_DIR" ]; then
  mkdir -p $JEMALLOC_DIR
  curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf - -C $JEMALLOC_DIR --strip-components=1
  cd $JEMALLOC_DIR
  ./configure --prefix=$JEMALLOC_DIR
  make
  make install
fi

# Print the location of libjemalloc.so for verification
echo "libjemalloc.so location: $JEMALLOC_DIR/lib/libjemalloc.so"
echo "Please set LD_PRELOAD to this path in your Render dashboard"

# Run the rest of your build process
cd $HOME/project/src  # Adjust this path if necessary
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile
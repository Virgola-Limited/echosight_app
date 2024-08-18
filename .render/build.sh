#!/usr/bin/env bash
set -o errexit

echo "==== Build Environment ===="
echo "PWD: $PWD"
echo "HOME: $HOME"
echo "RENDER_PROJECT_DIR: $RENDER_PROJECT_DIR"

# Install jemalloc in the correct directory
JEMALLOC_VERSION=5.3.0
JEMALLOC_DIR=/opt/render/project/src/jemalloc

if [ ! -d "$JEMALLOC_DIR" ]; then
  echo "Installing jemalloc..."
  mkdir -p $JEMALLOC_DIR
  curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf - -C $JEMALLOC_DIR --strip-components=1
  cd $JEMALLOC_DIR
  ./configure --prefix=$JEMALLOC_DIR
  make
  make install
  echo "jemalloc installation completed."
else
  echo "jemalloc directory already exists, skipping installation."
fi

# Print the location of libjemalloc.so for verification
echo "libjemalloc.so location: $JEMALLOC_DIR/lib/libjemalloc.so"
ls -l $JEMALLOC_DIR/lib/libjemalloc.so

echo "Content of JEMALLOC_DIR:"
ls -R $JEMALLOC_DIR

echo "Please ensure LD_PRELOAD is set to /opt/render/project/src/jemalloc/lib/libjemalloc.so in your Render dashboard"

# Run the rest of your build process
cd /opt/render/project/src
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile

echo "==== Final Build Directory Structure ===="
ls -R /opt/render/project/src
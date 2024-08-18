#!/usr/bin/env bash
set -o errexit

# Install jemalloc in a persistent directory
JEMALLOC_VERSION=5.3.0
JEMALLOC_DIR=$HOME/jemalloc

if [ ! -d "$JEMALLOC_DIR" ]; then
  mkdir -p $JEMALLOC_DIR
  curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf - -C $JEMALLOC_DIR --strip-components=1
  cd $JEMALLOC_DIR
  ./configure --prefix=$JEMALLOC_DIR
  make
  make install
fi

# Add jemalloc to LD_PRELOAD and update library path
echo "export LD_PRELOAD=$JEMALLOC_DIR/lib/libjemalloc.so" >> $HOME/.bashrc
echo "export LD_PRELOAD=$JEMALLOC_DIR/lib/libjemalloc.so" >> $HOME/.profile
echo "export LD_LIBRARY_PATH=$JEMALLOC_DIR/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo "export LD_LIBRARY_PATH=$JEMALLOC_DIR/lib:$LD_LIBRARY_PATH" >> $HOME/.profile

# Run the rest of your build process
cd $HOME/project/src  # Adjust this path if necessary
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile
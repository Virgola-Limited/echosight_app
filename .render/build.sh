#!/usr/bin/env bash
set -o errexit

# Install jemalloc
JEMALLOC_VERSION=5.3.0
curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf -
cd jemalloc-${JEMALLOC_VERSION}
./configure --prefix=$HOME/.jemalloc
make
make install

# Add jemalloc to LD_PRELOAD
echo "export LD_PRELOAD=$HOME/.jemalloc/lib/libjemalloc.so" >> $HOME/.bashrc

# Return to project directory
cd ..

# Run the rest of your build process
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile
bin/vite build
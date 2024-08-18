#!/usr/bin/env bash

# Install jemalloc
JEMALLOC_VERSION=5.3.0
curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 | tar xjf -
cd jemalloc-${JEMALLOC_VERSION}
./configure
make
sudo make install

# Return to project directory (if jemalloc step changes directory)
cd ..

# Run the rest of your build process
bundle install
yarn install
bundle exec rake db:migrate
RAILS_ENV=production bin/rails assets:precompile
bin/vite build

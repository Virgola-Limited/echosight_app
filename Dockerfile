# syntax = docker/dockerfile:1

# Use slim Ruby image as base
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Set working directory
WORKDIR /rails

# Set up environment variables for production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    NODE_ENV="production"

# Install packages required for building gems and running the application
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config curl

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

# Copy Gemfile and Gemfile.lock and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy package.json and package-lock.json (if you have them)
COPY package.json package-lock.json ./
RUN npm ci

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 \
    DATABASE_URL='postgresql://dummy:dummy@localhost/dummy' \
    bundle exec rake assets:precompile

# Remove packages used for building to reduce image size
RUN apt-get purge -y --auto-remove build-essential git pkg-config curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run as non-root user for security
RUN useradd -m rails && chown -R rails:rails /rails
USER rails

# Expose port and set the default command
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
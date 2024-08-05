web: jemalloc.sh bundle exec puma -C config/puma.rb
release: bundle exec rake db:migrate && bin/vite build
worker_default: bundle exec sidekiq -q default -q low_priority -C config/sidekiq.yml
worker_tweet_syncing: bundle exec sidekiq -q tweet_syncing -c 1
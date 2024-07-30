web: jemalloc.sh bundle exec puma -C config/puma.rb
release: bundle exec rake db:migrate && bin/vite build
worker: bundle exec sidekiq -q tweet_syncing -q default -q low_priority
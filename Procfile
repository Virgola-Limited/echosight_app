web: jemalloc.sh bundle exec puma -C config/puma.rb
release: bundle exec rake db:migrate && bin/vite build
worker: bundle exec sidekiq -C config/sidekiq.yml

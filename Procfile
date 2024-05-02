release: bundle exec rake db:migrate && bin/vite build
worker: bundle exec sidekiq -q default -q low_priority
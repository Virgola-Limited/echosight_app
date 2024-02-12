release: bundle exec rake db:migrate
worker: bundle exec sidekiq -q default
scheduler: IS_SCHEDULER=true bundle exec sidekiq -q default
# spec/initializers/sidekiq_spec.rb
require 'rails_helper'
require 'sidekiq/testing'
require 'sidekiq/cron/job'

RSpec.describe 'Sidekiq Cron Job Initialization' do
  before do
    # Suppress Sidekiq logger output
    @original_stdout = $stdout
    @original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    # Destroy existing jobs to ensure a clean state before each test
    Sidekiq::Cron::Job.destroy_all!
  end

  after do
    # Restore original stdout and stderr
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  context 'when loading the schedule YAML' do
    before do
      schedule_file = "config/sidekiq_schedule.yml"
      schedule = YAML.load(ERB.new(File.read(schedule_file)).result)
      Sidekiq::Cron::Job.load_from_hash(schedule)
    end

    it 'creates the cron jobs from the schedule file' do
      jobs = Sidekiq::Cron::Job.all

      expect(jobs.count).to eq(7) # Adjust the count if you add or remove jobs in the schedule file

      expect(jobs.map(&:name)).to include(
        'Queue Monitor - every 5 minutes',
        'Fetch Tweets',
        'Sync Subscriptions - every 1 hour',
        'Regenerate User Public Page Cache - every 3 hours',
        'Users Without Subscription Email - every 1 day',
        'capture_leaderboard_job',
        'identity_notifications_job'
      )
    end
  end

  context 'when destroying existing jobs' do
    before do
      # Create some dummy jobs
      Sidekiq::Cron::Job.create(name: 'Dummy Job 1', cron: '*/5 * * * *', class: 'DummyJob1')
      Sidekiq::Cron::Job.create(name: 'Dummy Job 2', cron: '*/10 * * * *', class: 'DummyJob2')

      Sidekiq::Cron::Job.destroy_all!
      schedule_file = "config/sidekiq_schedule.yml"
      schedule = YAML.load(ERB.new(File.read(schedule_file)).result)
      Sidekiq::Cron::Job.load_from_hash(schedule)
    end

    it 'deletes existing jobs before loading new ones' do
      jobs = Sidekiq::Cron::Job.all

      expect(jobs.count).to eq(7) # Adjust the count if you add or remove jobs in the schedule file

      expect(jobs.map(&:name)).not_to include(
        'Dummy Job 1',
        'Dummy Job 2'
      )
    end
  end
end

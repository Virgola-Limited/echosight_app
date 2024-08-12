# app/services/sidekiq_scheduled_jobs_import_service.rb
require 'sidekiq'
require 'sidekiq/api'
require 'json'

class SidekiqScheduledJobsImportService
  RENDER_REDIS_URL = ENV['RENDER_REDIS_URL']

  def self.import(json_file_path)
    puts "Starting import process..."

    # Read jobs from JSON file
    jobs = JSON.parse(File.read(json_file_path))
    puts "Read #{jobs.size} jobs from file"

    # Configure Sidekiq to use Render.com Redis
    Sidekiq.configure_client do |config|
      config.redis = { url: RENDER_REDIS_URL || ENV['REDIS_URL'] }
    end
    puts "Configured Sidekiq with Redis URL: #{RENDER_REDIS_URL || ENV['REDIS_URL']}"

    # Clear the existing scheduled set
    cleared_count = Sidekiq::ScheduledSet.new.clear
    puts "Cleared #{cleared_count} existing scheduled jobs"

    # Recreate jobs
    success_count = 0
    jobs.each_with_index do |job, index|
      begin
        klass = job['klass'].constantize
        at_time = Time.at(job['at'])

        # Use perform_at to properly schedule the job
        jid = klass.perform_at(at_time, *job['args'])

        if jid
          success_count += 1
        else
          puts "Failed to schedule job #{index}: #{job['klass']}"
        end
      rescue => e
        puts "Error importing job #{index}: #{e.message}"
      end

      if (index + 1) % 100 == 0
        puts "Processed #{index + 1} jobs..."
      end
    end

    puts "Import completed. Cleared #{cleared_count} existing scheduled jobs and successfully imported #{success_count} jobs to Redis."

    # Verify the import
    new_count = Sidekiq::ScheduledSet.new.size
    puts "New scheduled set size: #{new_count}"
  end
end

SidekiqScheduledJobsImportService.import('./jobs.json')
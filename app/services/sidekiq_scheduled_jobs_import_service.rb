require 'sidekiq'
require 'sidekiq/api'
require 'json'

class SidekiqScheduledJobsImportService
  def self.import(json_file_path)
    puts "Starting import process..."

    # Read jobs from JSON file
    jobs = JSON.parse(File.read(json_file_path))
    puts "Read #{jobs.size} jobs from file"

    # Clear the existing scheduled set
    cleared_count = Sidekiq::ScheduledSet.new.clear
    puts "Cleared #{cleared_count} existing scheduled jobs"

    # Recreate jobs
    success_count = 0
    jobs.each_with_index do |job, index|
      begin
        klass = job['klass'].constantize
        at_time = parse_time(job['at'])

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

  private

  def self.parse_time(time_string)
    Time.parse(time_string)
  rescue ArgumentError
    # If Time.parse fails, try to interpret it as a Unix timestamp
    Time.at(time_string.to_f)
  end
end

SidekiqScheduledJobsImportService.import('./jobs.json')
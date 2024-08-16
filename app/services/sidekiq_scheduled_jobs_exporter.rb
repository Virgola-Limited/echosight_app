require 'json'

class SidekiqScheduledJobsExporter
  def export
    jobs_array = fetch_scheduled_jobs
    output_to_console(jobs_array)
    jobs_array.size
  end

  private

  def fetch_scheduled_jobs
    scheduled_jobs = Sidekiq::ScheduledSet.new
    scheduled_jobs.map { |job| job_to_hash(job) }
  end

  def job_to_hash(job)
    {
      klass: job.klass,
      args: job.args,
      at: job.at,
      jid: job.jid
    }
  end

  def output_to_console(jobs_array)
    puts JSON.pretty_generate(jobs_array)
  end
end
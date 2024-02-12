class FailingJob
  include Sidekiq::Job

  def perform
    raise 'Intentional Failure'
  end
end

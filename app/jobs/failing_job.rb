class FailingJob
  include Sidekiq::Worker

  def perform
    raise 'Intentional Failure'
  end
end

module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job

    def perform
      Twitter::ExistingTweetsUpdater.call
    end
  end
end
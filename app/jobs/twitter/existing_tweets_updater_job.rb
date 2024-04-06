module Twitter
  class ExistingTweetsUpdaterJob
    include Sidekiq::Job

    def perform
      # Does this need to create an UserTwitterDataUpdate record?
      Twitter::ExistingTweetsUpdater.call
    end
  end
end
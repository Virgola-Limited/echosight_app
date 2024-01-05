# frozen_string_literal: true

class TweetCountsUpdaterWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    Twitter::TweetHourlyCountsUpdater.new(user, nil).call
  end
end

# frozen_string_literal: true

module Twitter
  class FollowersUpdaterJob < DataUpdateJobBase
    private

    def update_user(user, client_class = nil)
      raise 'Can get this from the tweet search now'
      client = client_class.new(user) if client_class
      updater_class.new(user:, client:).call
    end

    def updater_class
      FollowersUpdater
    end
  end
end

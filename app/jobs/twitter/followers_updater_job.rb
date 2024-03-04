module Twitter
  class FollowersUpdaterJob < DataUpdateJobBase
    private

    def update_user(user, client_class = nil)
      client = client_class.new(user) if client_class
      updater_class.new(user: user, client: client).call
    end

    def updater_class
      FollowersUpdater
    end
  end
end

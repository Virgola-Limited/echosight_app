module Twitter
  class FollowersUpdaterJob < DataUpdateJobBase
    private

    def update_user(user)
      FollowersUpdater.new(user).call
    end
  end
end

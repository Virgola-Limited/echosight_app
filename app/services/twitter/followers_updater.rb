# frozen_string_literal: true

module Twitter
  class FollowersUpdater
    attr_reader :user, :user_data, :twitter_client

    def initialize(user)
      @user = user
      @twitter_client = Twitter::Client.new(user)
    end

    def call
      store_followers
    end

    private


    def fetch_user_data
      @user_data ||= twitter_client.fetch_user_public_metrics
    end

    def store_followers
      fetch_user_data

      if user_data['data'] && user_data['data']['public_metrics']
        followers_count = user_data['data']['public_metrics']['followers_count']
        ::TwitterFollowersCount.find_or_initialize_by(
          identity_id: user.identity.id,
          date: Date.current
        ).update(
          followers_count: followers_count
        )
      end
    end

  end
end

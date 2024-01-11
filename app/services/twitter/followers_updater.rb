# frozen_string_literal: true

module Twitter
  class FollowersUpdater
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      store_followers
    end

    private

    # https://developer.twitter.com/en/portal/products/basic
    # GET /2/users
    # 100 requests / 24 hours
    # PER USER
    # 500 requests / 24 hours

    def fetch_recent_followers
      endpoint = "users/#{user.identity.uid}"
      params = {
        'user.fields' => 'public_metrics'
      }
      # {"data"=>{"public_metrics"=>{"followers_count"=>2, "following_count"=>11, "tweet_count"=>7, "listed_count"=>0, "like_count"=>4}, "id"=>"1691930809756991488", "username"=>"Topher179412184", "name"=>"Topher"}}
      x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def x_client
      @x_client ||= ClientService.new.client
    end

    def store_followers
      response = fetch_recent_followers
      Rails.logger.debug('paul response' + response.inspect)

      if response['data'] && response['data']['public_metrics']
        followers_count = response['data']['public_metrics']['followers_count']
        TwitterFollowerCount.find_or_initialize_by(
          identity_id: user.identity.id,
          date: Date.current
        ).update(
          followers_count: followers_count
        )
      end
    end
  end
end

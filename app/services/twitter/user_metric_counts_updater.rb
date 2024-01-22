# frozen_string_literal: true

module Twitter
  class UserMetricCountsUpdater # change name as it stores likes as well
    attr_reader :user, :user_data

    def initialize(user)
      @user = user
    end

    def call
      store_followers
      # store_likes
    end

    private

    # https://developer.twitter.com/en/portal/products/basic
    # GET /2/users
    # 100 requests / 24 hours
    # PER USER
    # 500 requests / 24 hours

    # Response: {"data"=>{"public_metrics"=>{"followers_count"=>2, "following_count"=>11, "tweet_count"=>7, "listed_count"=>0, "like_count"=>4}, "id"=>"1691930809756991488", "username"=>"Topher179412184", "name"=>"Topher"}}
    def fetch_user_data
      return user_data if user_data
      endpoint = "users/#{user.identity.uid}"
      params = {
        'user.fields' => 'public_metrics'
      }
      @user_data = x_client.get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def x_client
      @x_client ||= ClientService.new.client
    end

    def store_followers
      response = fetch_user_data

      if response['data'] && response['data']['public_metrics']
        followers_count = response['data']['public_metrics']['followers_count']
        ::TwitterFollowersCount.find_or_initialize_by(
          identity_id: user.identity.id,
          date: Date.current
        ).update(
          followers_count: followers_count
        )
      end
    end

    # lets aggrecate this data from tweets
    # def store_likes
    #   response = fetch_user_data
    #   if response['data'] && response['data']['public_metrics']
    #     likes_count = response['data']['public_metrics']['like_count']
    #     ::TwitterLikesCount.find_or_initialize_by(
    #       identity_id: user.identity.id,
    #       date: Date.current
    #     ).update(
    #       likes_count: likes_count
    #     )
    #   end
    # end
  end
end

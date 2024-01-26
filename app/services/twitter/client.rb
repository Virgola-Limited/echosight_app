# frozen_string_literal: true

module Twitter
  class Client
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end

    # https://developer.twitter.com/en/portal/products/basic
    # GET /2/users
    # 100 requests / 24 hours
    # PER USER
    # 500 requests / 24 hours

    # Response: {"data"=>{"public_metrics"=>{"followers_count"=>2, "following_count"=>11, "tweet_count"=>7, "listed_count"=>0, "like_count"=>4}, "id"=>"1691930809756991488", "username"=>"Topher179412184", "name"=>"Topher"}}
    def fetch_user_public_metrics
      endpoint = "users/#{user.identity.uid}"
      params = { 'user.fields' => 'public_metrics' }
      client(auth: :oauth1).get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def fetch_user_tweets(next_token = nil)
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics,non_public_metrics',
        'pagination_token' => next_token,
        'max_results' => 100
      }.compact
      client(auth: :oauth1).get("#{endpoint}?#{URI.encode_www_form(params)}")
    end

    def client(version: :v2, auth: :oauth2)
      X::Client.new(**credentials(version, auth))
    end

    private

    def credentials(version, auth)
      if user
        user_context_credentials(version)
      else
        application_context_credentials(version, auth)
      end
    end

    def user_context_credentials(version)
      {
        bearer_token: user.identity.bearer_token,
        base_url: base_url(version)
      }
    end

    def application_context_credentials(version, auth)
      credentials = { base_url: base_url(version) }

      case auth
      when :oauth2
        credentials[:bearer_token] = Rails.application.credentials.dig(:twitter, :bearer_token)
      when :oauth1
        credentials[:api_key] = Rails.application.credentials.dig(:twitter, :consumer_api_key)
        credentials[:api_key_secret] = Rails.application.credentials.dig(:twitter, :consumer_api_secret)
      end

      credentials
    end

    def base_url(version = :v2)
      version == :v1_1 ? 'https://api.twitter.com/1.1/' : 'https://api.twitter.com/2/'
    end
  end
end

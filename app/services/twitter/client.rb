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
      make_api_call(endpoint, params, :oauth1)
    end


    # | Endpoint                  | #Requests | Window of time | Per      | Part of the Tweet pull cap? | Effective 30-day limit |
    # |---------------------------|-----------|----------------|----------|-----------------------------|------------------------|
    # | GET_2_users_param_tweets  | 10        | 15 minutes     | per app  | yes                         | 10,000                 |
    # | GET_2_users_param_tweets  | 5         | 15 minutes     | per user | yes                         | 10,000                 |
    def fetch_user_tweets(next_token = nil)
      endpoint = "users/#{user.identity.uid}/tweets"
      params = {
        'tweet.fields' => 'created_at,public_metrics,non_public_metrics',
        'pagination_token' => next_token,
        'max_results' => 100
      }.compact
      make_api_call(endpoint, params, :oauth1)
    end

    private

    def client(version: :v2, auth: :oauth2)
      X::Client.new(**credentials(version, auth))
    end

    def make_api_call(endpoint, params, auth_type)
      response = client(auth: auth_type).get("#{endpoint}?#{URI.encode_www_form(params)}")
      response
    rescue X::Error => e # Assuming X::Error is the base class for errors from the X client
      error_details = {
        error: e.message,
        auth_type: auth_type.to_s,
        api_version: determine_api_version(endpoint),
        endpoint: endpoint,
        query_params: params,
        user_info: user_info_for_error
      }

      ExceptionNotifier.notify_exception(
        StandardError.new("Twitter API Error: #{e.message}"),
        data: error_details
      )
    end

    def determine_api_version(endpoint)
      endpoint.include?('/1.1/') ? 'v1.1' : 'v2'
    end

    def user_info_for_error
      return "User ID: #{user.identity.uid}, Email: #{user.email}" if user
      'Application Context'
    end

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

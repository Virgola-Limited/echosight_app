# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdater < Services::Base
    attr_reader :user, :client, :api_batch_id
    attr_accessor :updated_tweets, :unupdated_tweets

    def initialize(user:, api_batch_id:, client: nil)
      # This needs to check if the user account is still active
      @client = client || SocialData::ClientAdapter.new
      @user = user
      @api_batch_id = api_batch_id
      @updated_tweets = []
      @unupdated_tweets = []
    end

    def call
      fetch_and_process_tweets
    end

    private

    def fetch_and_process_tweets
      tweets = Tweet.where(api_batch_id: @api_batch_id, identity_id: user.identity.id).order(:id)
      min_tweet, max_tweet = tweets.first, tweets.last

      if min_tweet && max_tweet
        since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
        until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

        query = "from:#{user.handle} since_time:#{since_time} until_time:#{until_time}"
        params = { query: query }
        tweets_data = client.search_tweets(params) || {}
        tweet_ids = tweets_data.fetch(:tweet_ids, [])
        today_user_data = nil
        if (tweets.count != tweet_ids.count)
          message = "Tweet count mismatch for user #{user.handle}. Expected: #{tweet_ids.count}, Actual: #{tweets.count}"
          ExceptionHandling.notify_or_raise(message, data: { user: user.handle, received_tweet_ids: tweet_ids, expected_tweet_ids: tweets.map(&:id) })
        end

        tweets_data.each do |tweet_data|
          p tweet_data
        tweets_data['data'].each do |tweet_data|
          today_user_data ||= tweet_data['user']['data']
          result = process_tweet_data(tweet_data)
          if result[:success]
            @updated_tweets.push(result)
          else
            @unupdated_tweets.push(result[:tweet_id])
          end
        end

        if today_user_data
          @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
          IdentityUpdater.new(today_user_data).call
        end
      end
    end


    def id_to_time(tweet_id)
      # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
      ((tweet_id >> 22) + 1288834974657) / 1000
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user, api_batch_id: api_batch_id)
    end
  end
end

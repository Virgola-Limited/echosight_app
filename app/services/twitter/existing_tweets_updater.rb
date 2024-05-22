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
      expected_tweets = Tweet.empty_status.where(api_batch_id: @api_batch_id, identity_id: user.identity.id).order(:id)
      min_tweet, max_tweet = expected_tweets.first, expected_tweets.last

      if min_tweet && max_tweet
        since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
        until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

        query = "from:#{user.handle} since_time:#{since_time} until_time:#{until_time}"
        params = { query: query }
        tweets_data = client.search_tweets(params)
        received_tweet_ids = tweets_data['data'].map{ |tweet| tweet["id"] }.map(&:to_i)
        today_user_data = nil
        if (expected_tweets.count != received_tweet_ids.count)
          handle_tweet_count_mismatch(expected_tweets, received_tweet_ids)
        end
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

    def handle_tweet_count_mismatch(expected_tweets, received_tweet_ids)
      expected_tweet_ids = expected_tweets.map(&:id)
      missing_tweet_ids = expected_tweet_ids - received_tweet_ids
      extra_tweet_ids = received_tweet_ids - expected_tweet_ids
      message = "Tweet count mismatch for user #{user.handle}. \n\nExpected: #{expected_tweet_ids},  \n\nActual: #{received_tweet_ids},  \n\nMissing: #{missing_tweet_ids},  \n\nExtra: #{extra_tweet_ids}"
      Notifications::SlackNotifier.call(message: message, channel: :errors) if extra_tweet_ids.any?

      mark_tweets_as_potentially_deleted(missing_tweet_ids)
    end

    def mark_tweets_as_potentially_deleted(missing_tweet_ids)
      Tweet.where(id: missing_tweet_ids).update_all(status: 'potentially_deleted')
    end

    def id_to_time(tweet_id)
      # Ensure tweet_id is treated as a BigInt and perform the bit shift and addition
      timestamp_ms = (tweet_id >> 22) + 1288834974657
      # Convert from milliseconds to seconds to match the expected Unix timestamp format
      timestamp_s = timestamp_ms / 1000
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user, api_batch_id: api_batch_id)
    end
  end
end
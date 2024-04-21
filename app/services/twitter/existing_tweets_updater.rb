# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdater < Services::Base
    attr_reader :user, :client, :api_batch_id
    attr_accessor :updated_tweets, :unupdated_tweets

    def initialize(user:, api_batch_id:, client: nil)
      @client = client || SocialData::ClientAdapter.new
      @user = user
      @api_batch_id = api_batch_id
      @updated_tweets = []
      @unupdated_tweets = []
    end

    def call
      fetch_and_process_tweets
      send_slack_notification
    end

    private

    def fetch_and_process_tweets
      tweets = Tweet.where(api_batch_id: @api_batch_id, identity_id: user.identity.id).order(:id)
      min_tweet, max_tweet = tweets.first, tweets.last

      if min_tweet && max_tweet
        since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
        until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

        query = "from:#{user.handle} since_time:#{tweet_data[:since]} until_time:#{tweet_data[:until]}"
        params = { query: query }
        tweets_data = client.search_tweets(params)
        today_user_data = nil

        if (tweets.count != tweet_data[:tweet_ids].count)
          message = "Tweet count mismatch for user #{user.handle}. Expected: #{tweet_data[:tweet_ids].count}, Actual: #{tweets.count}"
          ExceptionNotifier.notify_exception(StandardError.new(message, data: { user: user.handle, tweet_data: tweet_data, tweets: tweets }))
        end


        tweets_data.each do |tweet_data|
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

    # chat gtp mistake
    # def id_to_time(tweet_id)
    #   # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
    #   time = ((tweet_id >> 22) + 1288834974657) / 1000
    #   Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%SZ') # Format time as ISO 8601 string
    # end

    def id_to_time(tweet_id)
      # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
      ((tweet_id >> 22) + 1288834974657) / 1000
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user)
    end

    def send_slack_notification
      if updated_tweets.empty? && unupdated_tweets.empty?
        message = "User: #{user.handle}: had no existing tweets to update"
      else
        updated_tweet_ids = []
        unupdated_tweets_ids = []
        if updated_tweets.count.positive?
          user = updated_tweets.first[:user]
          updated_tweet_ids = updated_tweets.map { |t| t[:tweet_id] }
        end
        if unupdated_tweets.count.positive?
          unupdated_tweets_ids = unupdated_tweets.map { |t| t[:tweet_id] }
        end
        message = "User: #{user.handle}: updated_tweets: #{updated_tweet_ids.join(' ')}, unupdated_tweets: #{unupdated_tweets_ids.join(' ')}"
      end
      # p message
      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end

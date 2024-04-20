# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdaterOld < Services::Base
    attr_reader :user, :client
    attr_accessor :updated_tweets, :unupdated_tweets

    # Dont change this it could unexpected consequences to the sync
    TIME_THRESHOLD = 24.hours.ago

    def initialize(user:, client: nil)
      raise 'Not used'
      @client = client || SocialData::ClientAdapter.new
      @user = user
      @updated_tweets = []
      @unupdated_tweets = []
    end

    def call
      fetch_and_store_tweets
      send_slack_notification
    end

    private

    def fetch_and_store_tweets
      first_update_tweet_data, subsequent_update_tweet_data = calculate_tweet_ranges(user)
      p first_update_tweet_data
      p subsequent_update_tweet_data
      if first_update_tweet_data[:valid_range]
        # p 'fetching first update tweets'
        fetch_and_process_tweets(first_update_tweet_data, user)
      end
      if subsequent_update_tweet_data[:valid_range]
        # p 'fetching subsequent update tweets'
        fetch_and_process_tweets(subsequent_update_tweet_data, user)
      end
    end

    def fetch_and_process_tweets(tweet_data, user)
      return unless user.handle && tweet_data[:since].present? && tweet_data[:until].present?

      query = "from:#{user.handle} since_time:#{tweet_data[:since]} until_time:#{tweet_data[:until]}"
      # p "JUST BEFORE SEARCH TWEETS: #{query}"
      params = { query: query }
      tweets = client.search_tweets(params)
      # p "JUST AFTER SEARCH TWEETS"
      today_user_data = nil
      # p "tweets ids returned #{tweets['data'].map {|t| t['id'] }}"
      # p tweets.count != tweet_data[:tweet_ids].count
      # if (tweets.count != tweet_data[:tweet_ids].count)
      #   message = "Tweet count mismatch for user #{user.handle}. Expected: #{tweet_data[:tweet_ids].count}, Actual: #{tweets.count}"
      #   ExceptionNotifier.notify_exception(StandardError.new(message, data: { user: user.handle, tweet_data: tweet_data, tweets: tweets }))
      # end
      p "**** TWEETS: #{tweets['data']}"
      tweets['data'].each do |tweet_data|
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

    def calculate_tweet_ranges(user)
      tweets_for_first_update_range = calculate_range(user: user)
      # p "tweets_for_first_update_range[:tweet_ids]: #{tweets_for_first_update_range[:tweet_ids].count}"
      # p "tweets_for_first_update_range: #{tweets_for_first_update_range}"
      # p "tweets_for_first_update_range: Tweet.where(id: #{tweets_for_first_update_range[:tweet_ids]}).map(&:tweet_metrics)"
      tweets_for_subsequent_updates_range = calculate_range(user: user, since: tweets_for_first_update_range[:since], for_subsequent_updates: true)
      # p "tweets_for_subsequent_updates_range count: #{tweets_for_subsequent_updates_range[:tweet_ids].count}"
      # p "tweets_for_subsequent_updates_range: #{tweets_for_subsequent_updates_range[:tweet_ids]}"
      # byebug
      # raise 'end'
      [tweets_for_first_update_range, tweets_for_subsequent_updates_range]
    end

    # scenarios

    # tweet is created with tweet metric
    # updater starts in the same day

    def calculate_range(user:, since: nil, for_subsequent_updates: false)
      base_query = Tweet.joins(:tweet_metrics).where(identity_id: user.identity.id)
      if for_subsequent_updates
        # Ensure that we only consider tweets for subsequent updates where the latest update is older than 24 hours
        tweets = base_query.group('tweets.id')
                           .having('MAX(tweet_metrics.pulled_at) < ?', TIME_THRESHOLD)
                           .having('COUNT(tweet_metrics.id) >= 2')
                          #  p "*********"
        # p "24 hours ago in test is #{TIME_THRESHOLD}"
        # p tweets.to_sql
        # p tweets.count
        # p "*********"

      else
        # first day tweets
        # dont include tweets with completed_first_day_metrics_at set
        tweets = base_query.group('tweets.id')
                           .having('COUNT(tweet_metrics.id) = 1 AND MAX(tweet_metrics.pulled_at) <= ?', TIME_THRESHOLD)
      end
      tweets = tweets.where('tweets.twitter_created_at > ?', 14.days.ago).order(:id).limit(2)
      min_tweet = tweets.min_by { |t| t.id }
      max_tweet = tweets.max_by { |t| t.id }

      since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
      until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

      { tweet_ids: tweets.map(&:id), min_tweet: min_tweet, max_tweet: max_tweet, since: since_time, until: until_time, valid_range: min_tweet.present? && max_tweet.present? }
    end

    def id_to_time(tweet_id)
      # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
      ((tweet_id >> 22) + 1288834974657) / 1000
    end

    # Used for debugging
    def id_to_human_time(tweet_id)
      Time.at(id_to_time(tweet_id)).utc
    end

    # expected.each do |tweet_id|
    #   human_readable_time = id_to_human_time(tweet_id)
    #   puts human_readable_time
    # end

    def process_tweet_data(tweet_data)
      # raise 'here'
      p tweet_data
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user)
    end

    def send_slack_notification
      if updated_tweets.empty? && unupdated_tweets.empty?
        message =  "User: #{user.handle}: had no existing tweets to update"
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
      Notifications::SlackNotifier.call(message: message, channel: :general)
    end
  end
end
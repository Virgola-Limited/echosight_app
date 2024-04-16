# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdater < Services::Base
    attr_reader :user, :client

    def initialize(user:, client: nil)
      @client = client || SocialData::ClientAdapter.new
      @user = user
    end

    def call
      # add logging later from new_tweets_fetcher.rb
      fetch_and_store_tweets
    end

    private

    def fetch_and_store_tweets
      first_update_tweet_data, subsequent_update_tweet_data = calculate_tweet_ranges(user)
      if first_update_tweet_data[:valid_range]
        p 'fetching first update tweets'
        fetch_and_process_tweets(first_update_tweet_data, user)
      end
      if subsequent_update_tweet_data[:valid_range]
        p 'fetching subsequent update tweets'
        fetch_and_process_tweets(subsequent_update_tweet_data, user)
      end
    end

    def fetch_and_process_tweets(tweet_data, user)
      return unless user.handle && tweet_data[:since].present? && tweet_data[:until].present?

      query = "from:#{user.handle} -filter:replies since_time:#{tweet_data[:since]} until_time:#{tweet_data[:until]}"
      p "query: #{query}"
      tweets = client.search_tweets(query: query)
      today_user_data = nil
      p "tweets #{tweets}"
      if (tweets.count > tweet_data[:tweet_ids].count)
        message = "Tweet count mismatch for user #{user.handle}. Expected: #{tweet_data[:tweet_ids].count}, Actual: #{tweets.count}"
        ExceptionNotifier.notify_exception(StandardError.new(message, data: { user: user.handle, tweet_data: tweet_data, tweets: tweets }))
      end
      tweets['data'].each do |tweet_data|
        today_user_data ||= tweet_data['user']['data']
        process_tweet_data(tweet_data)
      end
      if today_user_data
        @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
        IdentityUpdater.new(today_user_data).call
      end
    end

    def calculate_tweet_ranges(user)
      tweets_for_first_update_range = calculate_range(user: user, time_threshold: 24.hours.ago)
      p "tweets_for_first_update_range: #{tweets_for_first_update_range[:tweet_ids].count}"
      # p tweets_for_first_update_range[:tweet_ids].include?(1777616431053525427)
      tweets_for_subsequent_updates_range = calculate_range(user: user, time_threshold: 24.hours.ago, since: tweets_for_first_update_range[:since], for_subsequent_updates: true)
      p "tweets_for_subsequent_updates_range: #{tweets_for_subsequent_updates_range[:tweet_ids].count}"
      byebug
      raise 'end'
      [tweets_for_first_update_range, tweets_for_subsequent_updates_range]
    end


    def calculate_range(user:, time_threshold:, since: nil, for_subsequent_updates: false)
      base_query = Tweet.joins(:tweet_metrics).where(identity_id: user.identity.id)
      # tweet_ids = [1777610912565784664, 1777616431053525427]
      # p tweet_ids
      # tweets = base_query.where(id: tweet_ids)
      if for_subsequent_updates
        # Ensure that we only consider tweets for subsequent updates where the latest update is older than 24 hours
        tweets = base_query.group('tweets.id')
                           .where('tweets.twitter_created_at > ?', 14.days.ago)
                           .having('MAX(tweet_metrics.pulled_at) < ?', 24.hours.ago)
                           .having('COUNT(tweet_metrics.id) >= 2')
                          #  .limit(2)
      else
        # Initial updates only if pulled_at is exactly 24 hours ago, adjust this as per your logic
        tweets = base_query.group('tweets.id')
                           .where('tweets.twitter_created_at > ?', 14.days.ago)
                           .having('COUNT(tweet_metrics.id) = 1 AND MAX(tweet_metrics.pulled_at) <= ?', time_threshold)
                          #  .limit(2)
      end

      min_tweet = tweets.min_by { |t| t.id }
      max_tweet = tweets.max_by { |t| t.id }

      since_time = min_tweet ? id_to_time(min_tweet.id) - 1 : nil
      until_time = max_tweet ? id_to_time(max_tweet.id) + 1 : nil

      { tweet_ids: tweets.map(&:id), since: since_time, until: until_time, valid_range: min_tweet.present? && max_tweet.present? }
    end

    def id_to_time(tweet_id)
      # Shift right by 22 bits and add the Twitter epoch offset, then convert to seconds
      ((tweet_id >> 22) + 1288834974657) / 1000
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data, user: user)
    end
  end
end

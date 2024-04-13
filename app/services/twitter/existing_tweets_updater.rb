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
        tweets_for_first_update_params, tweets_for_subsequent_updates_params = calculate_tweet_ranges(user)
        if tweets_for_first_update_params[:valid_range]
          p 'fetching first update tweets'
          fetch_and_process_tweets(tweets_for_first_update_params, user)
        end
        if tweets_for_subsequent_updates_params[:valid_range]
          p 'fetching subsequent update tweets'
          fetch_and_process_tweets(tweets_for_subsequent_updates_params, user)
        end
        # add some logging later
      # rescue StandardError => e
      #   ExceptionNotifier.notify_exception(StandardError.new("DEBUG message (remove later): No tweets found for user"), data: user)
    end

    def fetch_and_process_tweets(params, user)
      return unless user.handle && params[:since].present? && params[:until].present?

      query = "from:#{user.handle} -filter:replies since_time:#{params[:since]} until_time:#{params[:until]}"
      p query
      tweets = client.search_tweets(query: query)
      p tweets
      today_user_data = nil
      # p "tweets #{tweets}"
      tweets['data'].each do |tweet_data|
        today_user_data ||= tweet_data['user']['data']
        process_tweet_data(tweet_data)
      end
      if today_user_data
        p today_user_data
        @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
        IdentityUpdater.new(today_user_data).call
      end
    end

    def calculate_tweet_ranges(user)
      tweets_for_first_update_range = calculate_range(user: user, time_threshold: 23.hours.ago)
      p "tweets_for_first_update_range: #{tweets_for_first_update_range}"
      tweets_for_subsequent_updates_range = calculate_range(user: user, time_threshold: 24.hours.ago, since: tweets_for_first_update_range[:since], for_subsequent_updates: true)
      p "tweets_for_subsequent_updates_range: #{tweets_for_subsequent_updates_range}"
      [tweets_for_first_update_range, tweets_for_subsequent_updates_range]
    end

    def calculate_range(user:, time_threshold:, since: nil, for_subsequent_updates: false)
      base_query = Tweet.joins(:tweet_metrics)
                        .where(identity_id: user.identity.id)

      if for_subsequent_updates
        tweets = base_query.where('tweet_metrics.pulled_at < ?', 24.hours.ago)
                           .group('tweets.id')  # Ensure you're grouping by the tweets' table ID
                           .having('MAX(tweet_metrics.pulled_at) < ?', 24.hours.ago)
      else
        tweets = base_query.where('twitter_created_at < ?', time_threshold)
                           .group('tweets.id')  # Ensure you're grouping by the tweets' table ID
                           .having('COUNT(tweet_metrics.id) = 1')
      end

      p "***tweets.count #{tweets.count}"

      min_tweet = tweets.min_by(&:twitter_id)
      max_tweet = tweets.max_by(&:twitter_id)

      since_time = id_to_time(min_tweet.twitter_id) - 1 if min_tweet
      until_time = id_to_time(max_tweet.twitter_id) + 1 if max_tweet

      { since: since_time, until: until_time, valid_range: min_tweet.present? && max_tweet.present? }
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

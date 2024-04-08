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
        fetch_and_process_tweets(tweets_for_first_update_params, user)
        fetch_and_process_tweets(tweets_for_subsequent_updates_params, user)
      rescue StandardError => e
        ExceptionNotifier.notify_exception(StandardError.new("DEBUG message (remove later): No tweets found for user"), data: user)
    end

    def fetch_and_process_tweets(params, user)
      params = { query: "from:#{user.handle} -filter:replies since_id:#{params[:since_id]} max_id:#{params[:max_id]}" }
      tweets = client.search_tweets(params)
      today_user_data = nil

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
      tweets_for_first_update_range = calculate_range(user, 23.hours.ago)
      tweets_for_subsequent_updates_range = calculate_range(user, 24.hours.ago, tweets_for_first_update_range[:since_id], for_subsequent_updates: true)

      [tweets_for_first_update_range, tweets_for_subsequent_updates_range]
    end

    def calculate_range(user, time_threshold, since_id = nil, for_subsequent_updates: false)
      base_query = Tweet.joins(:tweet_metrics)
                        .where(identity_id: user.identity.id)
                        .select(:id)

      if for_subsequent_updates
        tweet_ids = base_query.where('tweet_metrics.pulled_at < ?', 24.hours.ago)
                              .group(:id)
                              .having('MAX(tweet_metrics.pulled_at) < ?', 24.hours.ago)
                              .pluck(:twitter_id)
      else
        tweet_ids = base_query.where('twitter_created_at < ?', time_threshold)
                              .group(:id)
                              .having('COUNT(tweet_metrics.id) = 1')
                              .pluck(:twitter_id)
      end

      tweet_ids = tweet_ids.filter { |id| id > since_id } if since_id.present?

      raise StandardError.new("No tweet IDs found for the specified criteria") if tweet_ids.empty?

      min_id = tweet_ids.min
      max_id = tweet_ids.max

      { since_id: min_id, max_id: max_id }
    end

    def process_tweet_data(tweet_data)
      Twitter::TweetAndMetricUpserter.call(tweet_data: tweet_data)
    end
  end
end

# frozen_string_literal: true

module Twitter
  class ExistingTweetsUpdater < Services::Base
    attr_reader :user, :client

    def initialize(user:, client: nil)
      @user = user
      @client = client || SocialData::ClientAdapter.new(user)
    end

    def call
      tweets = client.fetch_tweets_by_ids(tweet_ids)

      # Need to call new service Twitter::TweetAndMetricUpserter

      # today_user_data = nil
      # metrics_created_count = 0
      # tweets_updated_count = 0

      # tweets['data'].each do |tweet_data|
      #   today_user_data ||= tweet_data['user']['data']
      #   metrics_created, tweet_updated = process_tweet_data(tweet_data)
      #   metrics_created_count += 1 if metrics_created
      #   tweets_updated_count += 1 if tweet_updated
      # end

      # if today_user_data
      #   @user_metrics_updated_message = UserMetricsUpdater.new(today_user_data).call
      #   IdentityUpdater.new(today_user_data).call
      # end

      # [metrics_created_count, tweets_updated_count]
    end

    private

    def tweet_ids
      # possible memoization later
      calculate_tweet_ids
    end

    def calculate_tweet_ids
      # Get IDs of syncable identities first
      syncable_identity_ids = Identity.joins(:user).merge(User.syncable).pluck(:id)

      # TO-DO: Change this to inclusion_ids as it should be a small queried set
      exclusion_ids = Tweet.where('twitter_created_at < ?', 15.days.ago).pluck(:id)

      # Find tweets created 23-24 hours ago with only one TweetMetric, belonging to syncable identities
      tweets_for_first_update = Tweet.joins(:tweet_metrics)
                                      .where(identity_id: syncable_identity_ids)
                                      .where('twitter_created_at < ?', 23.hours.ago)
                                      .where.not(id: exclusion_ids) # Exclude old tweets
                                      .group(:id)
                                      .having('COUNT(tweet_metrics.id) = 1')

                                      # Find tweets with the last TweetMetric pulled_at older than 24 hours, belonging to syncable identities
      tweets_for_subsequent_updates = Tweet.joins(:tweet_metrics)
                                            .where(identity_id: syncable_identity_ids)
                                            .where.not(id: tweets_for_first_update.select(:id) + exclusion_ids) # Exclude tweets already selected for first update and old tweets
                                            .where('tweet_metrics.pulled_at < ?', 24.hours.ago)
                                            .group(:id)
                                            .having('MAX(tweet_metrics.pulled_at) < ?', 24.hours.ago)

      # Combine both sets and map to tweet IDs
      tweet_ids_for_update = (tweets_for_first_update.pluck(:id) + tweets_for_subsequent_updates.pluck(:id)).uniq
      tweet_ids_for_update
    end


    def process_tweet_data(tweet_data)

    end
  end
end
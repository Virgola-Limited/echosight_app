# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::TweetMetricsQuery do
  let(:identity) { create(:identity, :random_credentials) }
  let(:user) { create(:user, identity:) }
  subject(:query) { described_class.new(user:) }

  describe '#top_tweets_for_user' do
    let!(:tweets) do
      [
        create(:tweet, identity:, twitter_created_at: 6.days.ago).tap do |tweet|
          create(:tweet_metric, tweet:, impression_count: 500)
        end,
        create(:tweet, identity:, twitter_created_at: 5.days.ago).tap do |tweet|
          create(:tweet_metric, tweet:, impression_count: 1500)
        end,
        create(:tweet, identity:, twitter_created_at: 4.days.ago).tap do |tweet|
          create(:tweet_metric, tweet:, impression_count: 200)
          create(:tweet_metric, tweet:, impression_count: 300)
        end,
        create(:tweet, identity:, twitter_created_at: 3.days.ago).tap do |tweet|
          create(:tweet_metric, tweet:, impression_count: 0)
        end
      ]
    end

    it 'returns tweets sorted by impression_count in descending order' do
      top_tweets = query.top_tweets_for_user
      expect(top_tweets.map(&:tweet_id)).to match_array(top_tweets.map(&:tweet_id).uniq)
      expect(top_tweets.map(&:impression_count)).to match_array([1500, 500, 300, 0])
    end
  end
end

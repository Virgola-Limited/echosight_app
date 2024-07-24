require 'rails_helper'

RSpec.describe Twitter::LeaderboardQuery, type: :query do
  describe '#snapshot' do
    let!(:identities) { create_list(:identity, 30) }
    let!(:tweets) { identities.each { |identity| create(:tweet, identity: identity, twitter_created_at: 1.hour.ago) } }
    let!(:tweet_metrics) { identities.each_with_index { |identity, index| create(:tweet_metric, tweet: identity.tweets.first, impression_count: (index + 1) * 10, created_at: 1.hour.ago) } }
    let!(:twitter_user_metrics) { identities.each_with_index { |identity, index| create(:twitter_user_metric, identity: identity, followers_count: (index + 1) * 100) } }

    it 'returns the correct snapshot data with identity attributes and aggregated metrics' do
      results = described_class.new.identity_leaderboard_snapshot.to_a

      expect(results.size).to eq(30)

      first_result = results.first
      last_result = results.last

      expect(first_result[:total_impressions]).to be > last_result[:total_impressions]
    end

    it 'returns an empty result when there are no tweets within the date range' do
      TweetMetric.update_all(created_at: 8.days.ago)

      results = described_class.new.identity_leaderboard_snapshot.to_a
      expect(results.size).to eq(0)
    end

    it 'limits the results to 25 when calling identity_leaderboard' do
      results = described_class.new(date_range: '7d').identity_leaderboard
      expect(results.size).to eq(25)
    end
  end
end

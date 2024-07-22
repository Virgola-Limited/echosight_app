# spec/queries/twitter/leaderboard_query_spec.rb

require 'rails_helper'

RSpec.describe Twitter::LeaderboardQuery, type: :query do
  describe '#snapshot' do
    let(:user) { create(:user) }
    let!(:identity1) { create(:identity, handle: 'user1', user: user) }
    let!(:identity2) { create(:identity, handle: 'user2') }
    let!(:tweet1) { create(:tweet, identity: identity1) }
    let!(:tweet2) { create(:tweet, identity: identity2) }
    let!(:tweet_metric1) { create(:tweet_metric, tweet: tweet1, impression_count: 100, retweet_count: 10, like_count: 20, quote_count: 5, reply_count: 2, bookmark_count: 3) }
    let!(:tweet_metric2) { create(:tweet_metric, tweet: tweet2, impression_count: 200, retweet_count: 20, like_count: 30, quote_count: 10, reply_count: 5, bookmark_count: 7) }
    let!(:twitter_user_metric1) { create(:twitter_user_metric, identity: identity1, followers_count: 1000) }
    let!(:twitter_user_metric2) { create(:twitter_user_metric, identity: identity2, followers_count: 2000) }

    it 'returns the correct snapshot data with identity attributes and aggregated metrics' do
      results = described_class.snapshot.to_a

      expect(results.size).to eq(2)

      first_result = results.find { |result| result.identity_id == identity2.id }
      second_result = results.find { |result| result.identity_id == identity1.id }

      expect(first_result.identity_id).to eq(identity2.id)
      expect(first_result.handle).to eq('user2')
      expect(first_result.total_impressions).to eq(200)
      expect(first_result.total_retweets).to eq(20)
      expect(first_result.total_likes).to eq(30)
      expect(first_result.total_quotes).to eq(10)
      expect(first_result.total_replies).to eq(5)
      expect(first_result.total_bookmarks).to eq(7)
      expect(first_result.total_followers).to eq(2000)
      expect(first_result.engagement_rate).to be_within(0.01).of(36.0)

      expect(second_result.identity_id).to eq(identity1.id)
      expect(second_result.handle).to eq('user1')
      expect(second_result.total_impressions).to eq(100)
      expect(second_result.total_retweets).to eq(10)
      expect(second_result.total_likes). to eq(20)
      expect(second_result.total_quotes).to eq(5)
      expect(second_result.total_replies).to eq(2)
      expect(second_result.total_bookmarks).to eq(3)
      expect(second_result.total_followers).to eq(1000)
      expect(second_result.engagement_rate).to be_within(0.01).of(40.0)
    end

    it 'returns an empty result when there are no tweets within the date range' do
      tweet_metric1.update(created_at: 8.days.ago)
      tweet_metric2.update(created_at: 8.days.ago)

      results = described_class.new(date_range: '7_days').snapshot.to_a
      expect(results.size).to eq(0)
    end
  end
end

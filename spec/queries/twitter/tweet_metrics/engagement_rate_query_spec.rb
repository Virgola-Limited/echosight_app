require 'rails_helper'

RSpec.describe Twitter::TweetMetrics::EngagementRateQuery do
  let(:identity) { create(:identity, :random_credentials) }
  let(:user) { create(:user, identity: identity) }
  subject(:query) { described_class.new(user: user) }

  describe '#engagement_rate_percentage_per_day' do
    context 'when there are no tweets' do
      it 'returns zero engagement rate for each day' do
        results = query.engagement_rate_percentage_per_day
        expect(results).to all(include(engagement_rate_percentage: 0))
      end
    end

    context 'when there are tweets without interactions or impressions' do
      before do
        # Create tweets for the past 7 days without interactions or impressions
        1.upto(7) do |n|
          tweet = create(:tweet, identity: identity, twitter_created_at: n.days.ago)
          create(:tweet_metric, :zero_metrics, tweet: tweet, pulled_at: n.days.ago)
        end
      end

      it 'returns zero engagement rate for each day' do
        results = query.engagement_rate_percentage_per_day
        expect(results).to all(include(engagement_rate_percentage: 0))
      end
    end

    context 'when there are tweets with varying interactions and impressions' do
      before do
        # Create tweets for the past 7 days with varying interactions and impressions
        1.upto(7) do |n|
          tweet = create(:tweet, identity: identity, twitter_created_at: n.days.ago)
          create(:tweet_metric, tweet: tweet, pulled_at: n.days.ago,
                 retweet_count: n * 2, quote_count: n, like_count: n * 3,
                 reply_count: n, bookmark_count: n, impression_count: n * 10)
        end
      end

      # fix later
      xit 'returns correct engagement rates for each day' do
        results = query.engagement_rate_percentage_per_day
        results.each_with_index do |result, index|
          total_interactions = ((7 - index) * 2) + (7 - index) + ((7 - index) * 3) + (7 - index) + (7 - index) # sum of interactions
          total_impressions = (7 - index) * 10
          expected_engagement_rate = (total_interactions.to_f / total_impressions) * 100

          expect(result[:engagement_rate_percentage]).to eq(expected_engagement_rate.round(2))
        end
      end
    end

    context 'when there are tweets from the same day with different metrics' do
      before do
        # Create multiple tweets from yesterday with varying interactions and impressions
        3.times do |n|
          tweet = create(:tweet, identity: identity, twitter_created_at: 1.day.ago)
          create(:tweet_metric, tweet: tweet, pulled_at: 1.day.ago,
                 retweet_count: 10, quote_count: 5, like_count: 15,
                 reply_count: 5, bookmark_count: 5, impression_count: 50 + n)
        end
      end

      it 'returns the correct engagement rate for the day' do
        result = query.engagement_rate_percentage_per_day.find { |r| r[:date] == Date.yesterday }
        total_interactions = (10 + 5 + 15 + 5 + 5) * 3 # sum of interactions for 3 tweets
        total_impressions = (50 + 0 + 50 + 1 + 50 + 2) # sum of impressions for 3 tweets
        expected_engagement_rate = (total_interactions.to_f / total_impressions) * 100

        expect(result[:engagement_rate_percentage]).to eq(expected_engagement_rate.round(2))
      end
    end
  end
end

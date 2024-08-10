require 'rails_helper'

RSpec.describe TweetMetric, type: :model do
  describe '#engagement_rate_percentage' do
    context 'when all interaction counts are zero' do
      let(:tweet_metric) { build(:tweet_metric, :zero_metrics) }

      it 'returns 0.0' do
        expect(tweet_metric.engagement_rate_percentage).to eq(0.0)
      end
    end

    context 'when there are interactions but zero impressions' do
      let(:tweet_metric) { build(:tweet_metric, impression_count: 0, retweet_count: 10, like_count: 5) }

      it 'returns 0.0' do
        expect(tweet_metric.engagement_rate_percentage).to eq(0.0)
      end
    end

    context 'when there are zero impressions and zero interactions' do
      let(:tweet_metric) { build(:tweet_metric, impression_count: 0, retweet_count: 0, like_count: 0, quote_count: 0, reply_count: 0, bookmark_count: 0) }

      it 'returns 0.0' do
        expect(tweet_metric.engagement_rate_percentage).to eq(0.0)
      end
    end

    context 'when there are impressions but zero interactions' do
      let(:tweet_metric) { build(:tweet_metric, impression_count: 100, retweet_count: 0, like_count: 0, quote_count: 0, reply_count: 0, bookmark_count: 0) }

      it 'returns 0.0' do
        expect(tweet_metric.engagement_rate_percentage).to eq(0.0)
      end
    end

    context 'when there are both interactions and impressions' do
      let(:tweet_metric) { build(:tweet_metric, impression_count: 100, retweet_count: 10, like_count: 20, quote_count: 5, reply_count: 2, bookmark_count: 3) }

      it 'calculates the correct engagement rate percentage' do
        expect(tweet_metric.engagement_rate_percentage).to eq(40.0)
      end
    end

    context 'when the engagement rate percentage is a fractional number' do
      let(:tweet_metric) { build(:tweet_metric, impression_count: 1234, retweet_count: 10, like_count: 20, quote_count: 5, reply_count: 2, bookmark_count: 3) }

      it 'returns the correct rounded engagement rate percentage' do
        expect(tweet_metric.engagement_rate_percentage).to eq(3.24)  # Example value, might need adjusting based on actual computation
      end
    end
  end
end

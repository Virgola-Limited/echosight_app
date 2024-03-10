require 'rails_helper'

RSpec.describe Twitter::TweetMetricsCleanupService do
  let(:identity) { create(:identity) }
  context 'when there is only 1 tweet metrics on the tweet' do
    let!(:tweet) { create(:tweet, identity: identity) }

    it 'does not delete the tweet metrics' do
      tweet_metrics = create(:tweet_metric, tweet: tweet)
      described_class.call
      expect(tweet.tweet_metrics.count).to eq(1)
    end
  end

  context 'when there are multiple tweet metrics on the tweet' do
    let(:expected_tweet_metrics) { [day_two_tweet_metrics, day_one_oldest_tweet_metrics] }
    let(:tweet) { create(:tweet, identity: identity) }
    let!(:day_two_tweet_metrics) { create(:tweet_metric, tweet: tweet, pulled_at: 2.days.ago) }
    let!(:tweet_metric) { create(:tweet_metric, tweet: tweet, pulled_at: 1.day.ago) }
    let!(:day_one_oldest_tweet_metrics) { create(:tweet_metric, tweet: tweet, pulled_at: 1.day.ago + 1.hour) }

    it 'deletes all but the last tweet metrics for a given day' do
      expect(tweet.tweet_metrics.count).to eq(3)
      described_class.call
      expect(tweet.tweet_metrics.count).to eq(2)
      expect(expected_tweet_metrics).to match_array(tweet.tweet_metrics)
    end
  end

  context 'when there are multiple tweets each with metrics' do
    let!(:tweet1) { create(:tweet, identity: identity) }
    let!(:tweet2) { create(:tweet, identity: identity) }
    let!(:tweet1_metric) { create(:tweet_metric, tweet: tweet1, pulled_at: 1.day.ago) }
    let!(:tweet2_metrics_yesterday) { create(:tweet_metric, tweet: tweet2, pulled_at: 2.days.ago) }
    let!(:tweet2_metrics_today) { create(:tweet_metric, tweet: tweet2, pulled_at: Date.current) }

    it 'correctly cleans up metrics for each tweet independently' do
      described_class.call
      expect(tweet1.tweet_metrics.count).to eq(1)
      expect(tweet2.tweet_metrics.count).to eq(2)
    end
  end

  # Scenario 3: No Tweet Metrics
  context 'when a tweet has no metrics' do
    let!(:tweet) { create(:tweet, identity: identity) }

    it 'does not raise any errors' do
      expect { described_class.call }.not_to raise_error
    end
  end

  # Scenario 6: Non-consecutive Days
  context 'when tweet metrics are not on consecutive days' do
    let!(:tweet) { create(:tweet, identity: identity) }
    let!(:day_one_metric) { create(:tweet_metric, tweet: tweet, pulled_at: 3.days.ago) }
    let!(:day_three_metric) { create(:tweet_metric, tweet: tweet, pulled_at: 1.day.ago) }

    it 'keeps the last tweet metric for each non-consecutive day' do
      described_class.call
      expect(tweet.tweet_metrics.count).to eq(2)
    end
  end

  # Scenario 7: Identical `pulled_at` Timestamps
  context 'when multiple metrics for a tweet have the exact same `pulled_at` timestamp' do
    let!(:tweet) { create(:tweet) }
    let(:identical_timestamp) { 1.day.ago }
    # Explicitly set the `created_at` to ensure metric2 is created after metric1
    let!(:metric1) { create(:tweet_metric, tweet: tweet, pulled_at: identical_timestamp, created_at: 2.hours.ago) }
    let!(:metric2) { create(:tweet_metric, tweet: tweet, pulled_at: identical_timestamp, created_at: 1.hour.ago) }

    it 'keeps the last created tweet metric with identical timestamps' do
      described_class.call
      expect(tweet.tweet_metrics.count).to eq(1)
      # Ensure the remaining metric is the one that was created last
      expect(tweet.tweet_metrics.first).to eq(metric2)
    end
  end
end

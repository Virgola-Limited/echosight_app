# spec/queries/twitter/tweet_metrics/impressions_query_spec.rb

require 'rails_helper'

RSpec.describe Twitter::TweetMetrics::ImpressionsQuery, type: :query do
  let(:user) { create(:user) }
  let(:identity) { create(:identity, user:) }

  let!(:old_tweets) do
    8.upto(13).map do |n|
      create(:tweet, identity:, twitter_created_at: n.days.ago).tap do |tweet|
        create(:tweet_metric, tweet:, pulled_at: n.days.ago, impression_count: 50 * n)
      end
    end
  end

  let!(:recent_tweets) do
    1.upto(7).map do |n|
      create(:tweet, identity:, twitter_created_at: n.days.ago).tap do |tweet|
        create(:tweet_metric, tweet:, pulled_at: n.days.ago, impression_count: 100 * n)
        # Adding a secondary metric to ensure the first metric is used
        create(:tweet_metric, tweet:, pulled_at: n.days.ago + 2.hours, impression_count: 0)
      end
    end
  end

  describe '#impressions_count' do
    it 'returns the sum of the impressions for the last 7 days' do
      query = Twitter::TweetMetrics::ImpressionsQuery.new(user:)
      expect(query.impressions_count).to eq(2800) # Sum of 100 * (1..7)
    end
  end

  xdescribe '#impressions_change_since_last_week' do
    it 'returns the percentage change in impressions since the previous week' do
      query = Twitter::TweetMetrics::ImpressionsQuery.new(user:)
      expect(query.impressions_change_since_last_week).to eq(460.0) # ((2800 - 500) / 500.0) * 100
    end
  end

  describe '#impression_counts_per_day' do
    it 'returns an array of daily impression counts for the last 7 days' do
      query = Twitter::TweetMetrics::ImpressionsQuery.new(user:)
      expected_counts = [
        { date: 7.days.ago.to_date, impression_count: 700 },
        { date: 6.days.ago.to_date, impression_count: 600 },
        { date: 5.days.ago.to_date, impression_count: 500 },
        { date: 4.days.ago.to_date, impression_count: 400 },
        { date: 3.days.ago.to_date, impression_count: 300 },
        { date: 2.days.ago.to_date, impression_count: 200 },
        { date: 1.day.ago.to_date, impression_count: 100 }
      ]
      expect(query.impression_counts_per_day).to eq(expected_counts)
    end
  end
end

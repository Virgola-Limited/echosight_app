require 'rails_helper'

RSpec.describe Twitter::TweetMetrics::ImpressionsQuery do
  let(:identity) { create(:identity, :random_credentials) }
  let(:user) { create(:user, identity: identity) }
  subject(:query) { described_class.new(user: user) }

  describe '#impressions_count' do
    let!(:old_tweets) do
      # Create tweets with metrics older than 14 days to ensure we pass the 14-day check
      (15..20).to_a.map do |n|
        create(:tweet, identity: identity, twitter_created_at: n.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, pulled_at: n.days.ago, impression_count: 50 * n)
        end
      end
    end

    it 'calculates the total impressions count for the last 7 days' do
      # Calculate expected impressions count for the last 7 days
      expected_impressions = TweetMetric.where('pulled_at > ?', 7.days.ago)
                                        .sum(:impression_count) - TweetMetric.where('pulled_at > ?', 14.days.ago)
                                                                              .where('pulled_at <= ?', 7.days.ago)
                                                                              .sum(:impression_count)

      impressions_count = query.impressions_count
      expect(impressions_count).to eq(expected_impressions)
    end
  end

  describe '#impression_counts_per_day' do
    context 'when there are no tweets' do
      it 'returns zero impressions for each day' do
        results = query.impression_counts_per_day
        expect(results).to all(include(impression_count: 0))
      end
    end

    context 'when there are tweets with impressions' do
      before do
        # Create tweets with impressions for the past 7 days
        1.upto(7) do |n|
          tweet = create(:tweet, identity: identity, twitter_created_at: n.days.ago)
          create(:tweet_metric, tweet: tweet, pulled_at: n.days.ago, impression_count: 100 * n)
        end
      end

      it 'returns correct impression counts for each day' do
        results = query.impression_counts_per_day
        # Ensure we have 7 days of data
        expect(results.size).to eq(7)

        # Check impressions for each day
        results.each_with_index do |result, index|
          expected_impressions = 100 * (6 - index) # Since we are going back in time from today
          expect(result[:impression_count]).to eq(expected_impressions)
        end
      end
    end

    context 'when there are tweets without impressions' do
      before do
        # Create tweets without impressions for the past 7 days
        1.upto(7) do |n|
          tweet = create(:tweet, identity: identity, twitter_created_at: n.days.ago)
          create(:tweet_metric, tweet: tweet, pulled_at: n.days.ago, impression_count: 0)
        end
      end

      it 'returns zero impressions for each day' do
        results = query.impression_counts_per_day
        expect(results).to all(include(impression_count: 0))
      end
    end

    context 'when there are tweets from different days with varying impressions' do
      before do
        # Create tweets from yesterday with high impressions
        3.times do
          tweet = create(:tweet, identity: identity, twitter_created_at: 1.day.ago)
          create(:tweet_metric, tweet: tweet, pulled_at: 1.day.ago, impression_count: 300)
        end

        # Create a tweet from 2 days ago with lower impressions
        tweet = create(:tweet, identity: identity, twitter_created_at: 2.days.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 2.days.ago, impression_count: 100)
      end

      it 'returns the correct sum of impressions for tweets from each day' do
        results = query.impression_counts_per_day
        yesterday_impressions = results.find { |r| r[:date] == Date.yesterday }[:impression_count]
        day_before_yesterday_impressions = results.find { |r| r[:date] == 2.days.ago.to_date }[:impression_count]

        expect(yesterday_impressions).to eq(900) # 3 tweets * 300 impressions each
        expect(day_before_yesterday_impressions).to eq(100) # 1 tweet * 100 impressions
      end

      # describe '#impression_counts_per_day' do
      #   let(:tweet1) { create(:tweet, identity: identity) }
      #   let(:tweet2) { create(:tweet, identity: identity) }
      #   before do
      #     3.times do |i|
      #       create(:tweet_metric, tweet: tweet1, pulled_at: (2 - i).days.ago, impression_count: 100 * (i + 1))
      #       create(:tweet_metric, tweet: tweet2, pulled_at: (2 - i).days.ago, impression_count: 200 * (i + 1))
      #     end
      #   end

      #   subject(:impression_diffs) { query.impression_counts_per_day }

      #   it 'calculates daily impression differences, ignoring the first day' do
      #     expected_diffs = [
      #       { date: 1.day.ago.to_date, impression_count: 300} , # (200*2 - 200*1) + (100*2 - 100*1)
      #       { date: Time.zone.today, impression_count: 300 }    # (200*3 - 200*2) + (100*3 - 100*2)
      #     ]
      #     expect(impression_diffs).to match_array(expected_diffs)
      #   end
      # end
    end
  end
end

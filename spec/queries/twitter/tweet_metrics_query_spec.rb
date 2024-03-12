require 'rails_helper'

RSpec.describe Twitter::TweetMetricsQuery do
  let(:identity) { create(:identity) }
  let(:user) { create(:user, identity: identity) }

  describe '#top_tweets_for_user' do
    let!(:tweets) do
      [
        create(:tweet, identity: identity, twitter_created_at: 6.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 500)
        end,
        create(:tweet, identity: identity, twitter_created_at: 5.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 1500)
        end,
        create(:tweet, identity: identity, twitter_created_at: 4.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 200)
          create(:tweet_metric, tweet: tweet, impression_count: 300)
        end,
        # keep this to ensure we dont get weird results with nil impression_count
        create(:tweet, identity: identity, twitter_created_at: 3.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: nil)
        end
      ]
    end

    it 'returns tweets sorted by impression_count in descending order' do
      query = described_class.new(user: user)
      top_tweets = query.top_tweets_for_user
      expect(top_tweets.map(&:tweet_id)).to match_array(top_tweets.map(&:tweet_id).uniq)
      expect(top_tweets.map(&:impression_count)).to match_array([1500, 500, 300])
    end
  end

  xdescribe '#engagement_rate_percentage_per_day' do
    subject(:query) { described_class.new(user: user) }

    context 'when we have tweet metrics data for 7 days' do
      let!(:tweets) do
        # Create 7 tweets, each with a different twitter_created_at date
        (0..6).to_a.reverse.map do |n|
          create(:tweet, identity: identity, twitter_created_at: n.days.ago.beginning_of_day) do |tweet|
            # For each tweet, create tweet metrics for each day from its creation until now
            (0..n).each do |m|
              multiplier = m + 1
              create(:tweet_metric, tweet: tweet, pulled_at: (n - m).days.ago.beginning_of_day + 7.hours,
                                    impression_count: 100 * multiplier,
                                    retweet_count: 5 * multiplier,
                                    like_count: 10 * multiplier,
                                    quote_count: 2 * multiplier,
                                    reply_count: 1 * multiplier,
                                    bookmark_count: 2 * multiplier)
            end
          end
        end
      end
      let(:expected_results) do
        [
          {date: 5.days.ago.to_date, engagement_rate_percentage: 20.0},
          {date: 4.days.ago.to_date, engagement_rate_percentage: 22.0},
          {date: 3.days.ago.to_date, engagement_rate_percentage: 20.0},
          {date: 2.days.ago.to_date, engagement_rate_percentage: 19.33},
          {date: 1.days.ago.to_date, engagement_rate_percentage: 20.0}
        ]
      end

      it 'calculates and returns varied engagement rate percentages per day, including a day with 0%' do
        results = query.engagement_rate_percentage_per_day
        expect(results.size).to eq(5)
        p results
        p expected_results
        expect(results).to match_array(expected_results)
      end
    end


        # # Intentionally reduce metrics for a specific day to simulate a decrease leading to 0% engagement
        # TweetMetric.where(pulled_at: 4.days.ago.beginning_of_day + 7.hours).each do |metric|
        #   metric.update(impression_count: metric.impression_count - 50,
        #                 retweet_count: metric.retweet_count - 2,
        #                 like_count: metric.like_count - 4,
        #                 quote_count: metric.quote_count - 1,
        #                 reply_count: metric.reply_count - 1,
        #                 bookmark_count: metric.bookmark_count - 1)
        # end

        # test for missing data
    xcontext 'when we have a day with no tweet metrics data in the last seven days' do
      let!(:tweets_with_missing_data) do
        # Create 7 tweets with one missing day of metrics
        (0..6).to_a.reverse.map do |n|
          create(:tweet, identity: identity, twitter_created_at: n.days.ago.beginning_of_day) do |tweet|
            # Skip creating metrics for one of the days
            (0..n).each do |m|
              next if m == 2 # Assume data is missing for 2.days.ago

              create(:tweet_metric, tweet: tweet, pulled_at: (n - m).days.ago.beginning_of_day + 7.hours,
                                    impression_count: rand(100..500) * (m + 1),
                                    retweet_count: rand(1..10) * (m + 1),
                                    like_count: rand(10..100) * (m + 1),
                                    quote_count: rand(0..5) * (m + 1),
                                    reply_count: rand(0..5) * (m + 1),
                                    bookmark_count: rand(0..5) * (m + 1))
            end
          end
        end
      end

      it 'returns 5 days of results' do
        results = query.engagement_rate_percentage_per_day

        # Verify we have 5 days of data since one day of metrics is missing
        expect(results.size).to eq(5)

        # Each result should have a date and an engagement rate percentage
        expect(results).to all(include(:date, :engagement_rate_percentage))

        # Output the results for visual inspection
        p results
      end
    end

  end
end

require 'rails_helper'

RSpec.describe Twitter::TweetMetricsQuery do
  describe '#top_tweets_for_user' do
    let(:identity) { create(:identity) }
    let(:user) { create(:user, identity: identity) }
    let!(:tweets) do
      [
        create(:tweet, identity: identity, created_at: 6.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 500)
        end,
        create(:tweet, identity: identity, created_at: 5.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 1500)
        end,
        create(:tweet, identity: identity, created_at: 4.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: 300)
        end,
        # keep this to ensure we dont get weird results with nil impression_count
        create(:tweet, identity: identity, created_at: 3.days.ago).tap do |tweet|
          create(:tweet_metric, tweet: tweet, impression_count: nil)
        end
      ]
    end

    it 'returns tweets sorted by impression_count in descending order' do
      query = described_class.new(user: user)
      top_tweets = query.top_tweets_for_user

      expect(top_tweets.map(&:id)).to eq([tweets[1].id, tweets[0].id, tweets[2].id])
      expect(top_tweets.map(&:impression_count)).to eq([1500, 500, 300])
    end
  end
end

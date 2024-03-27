require 'rails_helper'

RSpec.describe Twitter::PostCountsQuery do
  let(:identity) { create(:identity, :random_credentials) }
  let(:user) { create(:user, identity: identity) }
  subject(:query) { described_class.new(user: user) }

  describe '#staggered_tweets_count_difference' do
    context 'when there is one days of tweets' do
      let!(:tweet) { create(:tweet, identity: identity, twitter_created_at: DateTime.now) }

      it 'returns comparison days 1, no difference and recent count 1' do
        query = described_class.new(user: user)
        result = query.staggered_tweets_count_difference
        expect(query.staggered_tweets_count_difference).to eq({:days_of_data=>1, :difference=>nil, :recent_count=>1})
      end
    end

    context 'when there are two days of tweet metrics data' do
    end

  end
end

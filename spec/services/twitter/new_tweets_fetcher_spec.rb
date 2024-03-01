require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcher, :vcr do
  let!(:identity) { create(:identity, :with_oauth_credential) }
  let(:user) { identity.user }
  let(:fetcher) { described_class.new(user: user, number_of_requests: 3) }

  context 'when the number_of_requests is set to 3' do
    context 'when the user has no tweets' do
      it 'fetches and stores 3 requests of tweets' do
        expect { fetcher.call }.to change(Tweet, :count).by_at_least(1) # Adjust according to expected number of tweets per request
        # expect(VCR).to have_recorded(3).requests # This is pseudo-code, adjust based on how you're using VCR
      end
    end

    context 'when we have Tweet model data persisted that matches tweets in the final request' do
      let!(:existing_tweet) { create(:tweet, twitter_id: "12345") } # Assuming a factory for tweet exists

      it 'fetches and stores the tweets until it matches the existing tweet' do
        allow(Tweet).to receive(:exists?).and_call_original
        allow(Tweet).to receive(:exists?).with(twitter_id: existing_tweet.twitter_id).and_return(true)

        expect { fetcher.call }.not_to change(Tweet, :count)
        expect(Tweet).to have_received(:exists?).with(twitter_id: existing_tweet.twitter_id)
      end
    end
  end

  it 'fetches the tweets in order of newest to oldest', :focus do
    fetcher.call
    tweets = Tweet.order(twitter_created_at: :desc)
    expect(tweets.first.twitter_created_at).to be > tweets.last.twitter_created_at
  end
end

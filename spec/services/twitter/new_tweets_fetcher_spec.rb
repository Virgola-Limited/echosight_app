# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcher, :vcr do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:first_tweet_attributes) do
    {
      'twitter_id' => 1_763_545_800_431_550_673,
      'text' => 'A tech innovation that excites you for the future?',
      'identity_id' => identity.id
    }
  end

  xcontext 'when the number_of_requests is set to 3' do
    let(:subject) { described_class.new(user:, number_of_requests: 3) }

    context 'when the user has no tweets' do
      it 'fetches and stores 3 requests of tweets' do
        expect { subject.call }.to change { user.reload.tweets.count }.by(61)
        attributes = user.tweets.last.attributes.slice(*first_tweet_attributes.keys)
        expect(attributes).to eq(first_tweet_attributes)
      end

      context 'when we have Tweet model data persisted that matches tweets in the final request' do
        # let!(:existing_tweet) { create(:tweet, twitter_id: '12345') } # Assuming a factory for tweet exists
        let(:subject) { described_class.new(user:) }

        it 'fetches and stores the tweets until it matches the existing tweet' do
          allow(Tweet).to receive(:exists?).and_call_original
          allow(Tweet).to receive(:exists?).with(twitter_id: existing_tweet.twitter_id).and_return(true)

          expect { subject.call }.not_to change(Tweet, :count)
          expect(Tweet).to have_received(:exists?).with(twitter_id: existing_tweet.twitter_id)
        end
      end
    end
  end

  let(:subject) { described_class.new(user:, number_of_requests: 1) }

  xit 'fetches the tweets in order of newest to oldest' do
    subject.call
    tweets = Tweet.order(twitter_created_at: :desc).pluck(:twitter_created_at)

    tweets.each_cons(2) do |a, b|
      expect(a).to be >= b
    end
  end
end

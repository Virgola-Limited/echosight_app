# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialData::ClientAdapter,
  vcr: { cassette_name: 'SocialData__Client_fetch_user_tweets_fetches_new_tweets_from_the_API.yml' } do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity:) }
  let(:client_adapter) { described_class.new(user) }

  describe '#fetch_user_tweets' do
    it 'returns adapted social data in the expected format' do
      adapted_data = client_adapter.fetch_user_tweets
      expect(adapted_data).to be_a(Hash)
      expect(adapted_data['data']).to be_an(Array)
      expect(adapted_data['data'].last).to eq(first_tweet)
    end

    let(:tweet_user_data) do
      {
        'data' => {
          'id' => '1691930809756991488',
          'name' => 'Topher',
          'username' => 'TopherToy',
          'public_metrics' =>
          {
            'followers_count' => 3,
            'following_count' => 16,
            'listed_count' => 0,
            'tweet_count' => 15
          },
          'image_url' => 'https://pbs.twimg.com/profile_images/1729697224278552576/pa9ZhTkQ_normal.jpg',
          'banner_url' => 'https://pbs.twimg.com/profile_banners/1691930809756991488/1702516482'
        }
      }
    end

    let(:first_tweet) do
      {
        'id' => '1740498992587567374',
        'text' => 'test',
        'created_at' => '2023-12-28T22:24:31.000000Z',
        'public_metrics' => {
          'impression_count' => 5,
          'like_count' => 0,
          'quote_count' => 0,
          'reply_count' => 0,
          'retweet_count' => 0,
          'bookmark_count' => 0
        },
        'is_pinned' => 'false',
        'user' => tweet_user_data
      }
    end
  end

  describe '#fetch_user_with_metrics' do
    it 'returns adapted social data in the expected format' do
      adapted_data = client_adapter.fetch_user_with_metrics
      expect(adapted_data).to eq(adapted_user_data)
    end

    let(:adapted_user_data) do
      {
        'data' => {
          'id' => '1691930809756991488',
          'name' => 'Topher',
          'username' => 'TopherToy',
          'public_metrics' => {
            'followers_count' => 3,
            'following_count' => 16,
            'listed_count' => 0,
            'tweet_count' => 15,
          },
          'image_url' => 'https://pbs.twimg.com/profile_images/1729697224278552576/pa9ZhTkQ_normal.jpg',
          'banner_url' => 'https://pbs.twimg.com/profile_banners/1691930809756991488/1702516482'
        }
      }
    end
  end

  describe '#search_tweets' do
    let(:params) { { query: 'from:elonmusk' } }
    it 'returns adapted social data in the expected format' do
      VCR.use_cassette('SocialData__Client_search_tweets_when_providing_within_time_parameter_fetches_tweets_for_that_time_frame.yml') do
        adapted_data = client_adapter.search_tweets(params, true)
        expect(adapted_data).to be_a(Hash)
        expect(adapted_data['data']).to be_an(Array)
        expect(adapted_data['data'].last).to eq(first_tweet)
        expect(adapted_data['data'].size).to eq(20)
      end
    end

    let(:tweet_user_data) do
      {
        'data' => {
          'id' => '44196397',
          'name' => 'Elon Musk',
          'username' => 'elonmusk',
          'public_metrics' =>
          {
            'followers_count' => 175_225_033,
            'following_count' => 551,
            'listed_count' => 149_016,
            'tweet_count' => 39_250
          },
          'image_url' => 'https://pbs.twimg.com/profile_images/1683325380441128960/yRsRRjGO_normal.jpg',
          'banner_url' => 'https://pbs.twimg.com/profile_banners/44196397/1690621312'
        }
      }
    end

    let(:first_tweet) do
      {
        'id' => '1765035782774137074',
        'text' => 'Sorry to bother everyone with this note, as it applies to people in the greater Austin area, but please go to the polls and vote for a new District Attorney!',
        'created_at' => '2024-03-05T15:24:58.000000Z',
        'public_metrics' => {
          'like_count' => 35_437,
          'quote_count' => 235,
          'reply_count' => 2069,
          'retweet_count' => 7846,
          'impression_count' => 6796646,
          'bookmark_count' => 417
        },
        'is_pinned' => 'false',
        'user' => tweet_user_data
      }
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialData::ClientAdapter, :vcr do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity:) }
  let(:client_adapter) { described_class.new }

  describe '#search_tweets' do
    # this is 1 second before the unix timestamp of this  1765212190418899365 and 1 second fater
    let(:params) { { query: 'from:tophertoy since_time:1709694355 until_time:1709694357' } }

    it 'returns adapted social data in the expected format' do
        adapted_data = client_adapter.search_tweets(params, true)
        expect(adapted_data).to be_a(Hash)
        expect(adapted_data['data'].size).to eq(1)
        expect(adapted_data['data'].last).to eq(first_tweet)
    end

    let(:tweet_user_data) do
      {
        'data' => {
          'id' => '1691930809756991488',
          'name' => 'Topher',
          'username' => 'TopherToy',
          'description' => 'Twitter/X analytics with Echosight https://t.co/uZpeIYc5Nq',
          'public_metrics' =>
          {
            'followers_count' => 13,
            'following_count' => 21,
            'listed_count' => 0,
            'tweet_count' => 40
          },
          'image_url' => 'https://pbs.twimg.com/profile_images/1770204882819223552/vrBPzd16_normal.jpg',
          'banner_url' => 'https://pbs.twimg.com/profile_banners/1691930809756991488/1710884709'
        }
      }
    end

    let(:first_tweet) do
      {
        'id' => '1765212190418899365',
        'text' => 'to come to',
        'created_at' => '2024-03-06T03:05:56.000000Z',
        'public_metrics' => {
          'like_count' => 0,
          'quote_count' => 0,
          'reply_count' => 0,
          'retweet_count' => 0,
          'impression_count' => 11,
          'bookmark_count' => 0
        },
        'is_pinned' => 'false',
        'user' => tweet_user_data
      }
    end
  end
end

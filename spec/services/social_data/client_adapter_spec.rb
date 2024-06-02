# frozen_string_literal: true

require 'rails_helper'


RSpec.describe SocialData::ClientAdapter do
  let(:identity) { create(:identity, :loftwah) }
  let(:user) { identity.user }
  let(:client_adapter) { described_class.new(user: user) }

  def id_to_time(tweet_id)
    # Ensure tweet_id is treated as a BigInt and perform the bit shift and addition
    timestamp_ms = (tweet_id >> 22) + 1288834974657
    # Convert from milliseconds to seconds to match the expected Unix timestamp format
    timestamp_s = timestamp_ms / 1000
  end

  describe '#search_tweets' do
    context 'when providing since_time and until_time parameters' do
      let(:since_time) { 1713785823 } # Earlier time
      let(:until_time) { 1713841157 } # Later time

      let(:params) { { query: "from:#{user.handle} since_time:#{since_time} until_time:#{until_time}" } }

      it 'returns adapted social data in the expected format' do
        VCR.use_cassette('SocialData__Client') do
          adapted_data = client_adapter.search_tweets(params)
          expect(adapted_data['data'].size).to eq(80)
          adapted_data['data'].each do |tweet|
            tweet_time = id_to_time(tweet['id'].to_i)
            expect(tweet_time).to be >= since_time
            expect(tweet_time).to be <= until_time
          end

          first_tweet = adapted_data['data'].first
          keys_to_test = first_tweet_expected_results.keys.excluding('created_at')
          keys_to_test.each do |key|
            if first_tweet[key].is_a?(Hash)
              expect(first_tweet[key].keys).to match_array(first_tweet_expected_results[key].keys)
            else
              expect(first_tweet[key]).to eq(first_tweet_expected_results[key]), "Expected value for key '#{key}' in first_tweet to be '#{first_tweet_expected_results[key]}', but got '#{first_tweet[key]}'"
            end
          end
        end
      end

      let(:tweet_user_data) do
        {
          'data' => {
            'id' => '1192091185',
            'name' => 'Loftwah',
            'username' => 'loftwah',
            'description' => 'Revolutionize Your Social Media Strategy with Echosight | https://t.co/wMI0Lub79k | https://t.co/HLB3aL1jca | https://t.co/IbbT2ncYyt | https://t.co/i9vT0NmOyw',
            'public_metrics' =>
            {
              'followers_count' => 7190,
              'following_count' => 5176,
              'listed_count' => 45,
              'tweet_count' => 58724
            },
            'image_url' => 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg',
            'banner_url' => 'https://pbs.twimg.com/profile_banners/1192091185/1711023494'
          }
        }
      end

      let(:first_tweet_expected_results) do
        {
          'id' => '1782583194291945673',
          "in_reply_to_status_id" => 1782565821971066897,
          'text' => '@Heather81031325 Gross but fascinating.',
          'source' => '<a href="https://mobile.twitter.com" rel="nofollow">Twitter Web App</a>',
          'created_at' => '2024-03-06T03:05:56.000000Z',
          'public_metrics' => {
            'like_count' => 0,
            'quote_count' => 0,
            'reply_count' => 0,
            'retweet_count' => 0,
            'impression_count' => 24,
            'bookmark_count' => 0
          },
          'is_pinned' => 'false',
          'user' => tweet_user_data
        }
      end
    end

    # Fix later
    xcontext 'when providing within_time parameter' do
      it 'fetches tweets and user for that time frame including user data' do
        VCR.use_cassette('SocialData__Client') do
          params = { query: "from:#{user.handle} within_time:2h" }
          response = client.search_tweets(params)

          # expect(response['tweets'].count).to eq(1)
          # response['tweets'].each do |tweet|
          #   tweet_created_at = Time.parse(tweet['tweet_created_at'])
          #   expect(tweet_created_at).to be_within(2.hours).of(vcr_response_time)

          #   null_tweet_keys.each do |key|
          #     expect(tweet[key]).to be_nil
          #   end

          #   expect(tweet).to include('user')
          #   expect(tweet['user'].keys).to match_array(user_keys)
          #   non_null_user_keys.each do |key|
          #     expect(tweet['user'][key]).to_not be_nil
          #   end
          # end
        end
      end
    end
  end
end

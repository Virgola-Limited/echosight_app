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

      def check_keys_and_values(actual, expected)
        actual.each do |key, value|
          if value.is_a?(Hash)
            expect(value.keys).to match_array(expected[key].keys)
            check_keys_and_values(value, expected[key])
          else
            expect(value).to eq(expected[key]), "Expected value for key '#{key}' to be '#{expected[key]}', but got '#{value}'"
          end
        end
      end

      it 'returns adapted social data in the expected format' do
        VCR.use_cassette('SocialData__Client') do
          adapted_data = client_adapter.search_tweets(params)

          # Check the 'tweets' key
          expect(adapted_data).to have_key('tweets')
          expect(adapted_data['tweets']['data'].size).to eq(80)

          # Check the tweets themselves
          adapted_data['tweets']['data'].each do |tweet|
            tweet_time = id_to_time(tweet['id'].to_i)
            expect(tweet_time).to be >= since_time
            expect(tweet_time).to be <= until_time
          end

          first_tweet = adapted_data['tweets']['data'].first
          keys_to_test = first_tweet_expected_results.keys.excluding('created_at')
          keys_to_test.each do |key|
            if first_tweet[key].is_a?(Hash)
              check_keys_and_values(first_tweet[key], first_tweet_expected_results[key])
            else
              expect(first_tweet[key]).to eq(first_tweet_expected_results[key]), "Expected value for key '#{key}' in first_tweet to be '#{first_tweet_expected_results[key]}', but got '#{first_tweet[key]}'"
            end
          end

          # Check the 'request_log' key (new check)
          expect(adapted_data).to have_key('request_log')
          expect(adapted_data['request_log']).to be_a(RequestLog)
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
            'can_dm' => false,
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
  end
end

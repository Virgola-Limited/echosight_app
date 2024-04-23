# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialData::Client do
  let(:identity) { create(:identity, :loftwah) }
  let(:user) { identity.user }
  let(:client) { described_class.new(user) }

  describe '#search_tweets' do
    context 'when providing within_time parameter' do
      context 'when there are less than 1 page of tweets' do
        let(:user_keys) do
          %w[id id_str name screen_name location url description protected verified
             followers_count friends_count listed_count favourites_count statuses_count created_at profile_banner_url profile_image_url_https can_dm]
        end
        let(:non_null_user_keys) do
          %w[id id_str name screen_name followers_count friends_count listed_count
             favourites_count statuses_count created_at profile_banner_url profile_image_url_https]
        end

        let(:null_tweet_keys) do
          %w[in_reply_to_status_id in_reply_to_status_id_str in_reply_to_user_id in_reply_to_user_id_str in_reply_to_screen_name]
        end

        fit 'fetches tweets and user for that time frame including user data' do
          VCR.use_cassette('SocialData__Client') do
            params = { query: "from:#{user.handle} within_time:2h" }
            response = client.search_tweets(params)

            # Extract the response time from the VCR cassette
            vcr_response_time = Time.parse('Tue, 23 Apr 2024 02:59:32 GMT')
            expect(response['tweets'].count).to eq(5)
            response['tweets'].each do |tweet|
              tweet_created_at = Time.parse(tweet['tweet_created_at'])
              expect(tweet_created_at).to be_within(2.hours).of(vcr_response_time)

              null_tweet_keys.each do |key|
                expect(tweet[key]).to be_nil
              end

              expect(tweet).to include('user')
              expect(tweet['user'].keys).to match_array(user_keys)
              non_null_user_keys.each do |key|
                expect(tweet['user'][key]).to_not be_nil
              end
            end
          end
        end
      end

      context 'when there are more than 1 page of tweets' do

      end
    end
  end
end

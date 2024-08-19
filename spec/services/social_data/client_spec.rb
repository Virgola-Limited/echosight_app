# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialData::Client do
  let(:identity) { create(:identity, :loftwah) }
  let(:user) { identity.user }
  let(:client) { described_class.new(user: user) }

  xdescribe '#fetch_user_details' do
    let(:user_id) { user.identity.uid.to_i }
    let(:expected_keys) do
      %w[id id_str name screen_name location url description protected verified
        followers_count friends_count listed_count favourites_count statuses_count created_at profile_banner_url profile_image_url_https]
    end

    it 'fetches user details by user_id' do
      VCR.use_cassette('SocialData__Client') do
        response = client.fetch_user_details(user_id)

        expect(response).to include(*expected_keys)
        expect(response['id']).to eq(user_id)
        expect(response['name']).to eq('Loftwah')
        expect(response['screen_name']).to eq('loftwah')
      end
    end
  end

  describe '#search_tweets' do
    let(:user_keys) do
      %w[id id_str name screen_name location url description protected verified
        followers_count friends_count listed_count favourites_count statuses_count created_at profile_banner_url profile_image_url_https can_dm]
    end
    let(:non_null_user_keys) do
      %w[id id_str name screen_name followers_count friends_count listed_count
        favourites_count statuses_count created_at profile_banner_url profile_image_url_https can_dm]
    end

    let(:null_tweet_keys) do
      %w[in_reply_to_status_id in_reply_to_status_id_str in_reply_to_user_id in_reply_to_user_id_str in_reply_to_screen_name]
    end

    # Extract the response time from the VCR cassette
    let(:vcr_response_time) { Time.parse('Tue, 23 Apr 2024 05:56:04 GMT') }

    context 'when providing within_time parameter' do
      context 'when there are less than 1 page of tweets' do
        it 'fetches tweets and user for that time frame including user data and returns the request log' do
          VCR.use_cassette('SocialData__Client') do
            params = { query: "from:#{user.handle} within_time:2h" }
            response = client.search_tweets(params)

            # Check that tweets are returned
            expect(response['tweets'].count).to eq(1)
            response['tweets'].each do |tweet|
              tweet_created_at = Time.parse(tweet['tweet_created_at'])
              expect(tweet_created_at).to be_within(2.hours).of(vcr_response_time)

              null_tweet_keys.each do |key|
                expect(tweet[key]).to be_nil
              end

              expect(tweet).to include('user')
              expect(tweet['user'].keys).to match_array(user_keys)
              non_null_user_keys.each do |key|
                expect(tweet['user'][key]).to_not be_nil, "key: #{key}"
              end
            end

            # Check that the request_log is returned
            expect(response).to include('request_log')
            expect(response['request_log']).to be_a(RequestLog)

            # Validate the contents of the request_log
            request_log = response['request_log']
            expect(request_log.endpoint).to eq('search')
            expect(request_log.params['query']).to eq("from:#{user.handle} within_time:2h")
          end
        end
      end

      context 'when there are more than 1 page of tweets' do
        it 'fetches both pages of tweets and consolidates the responses and returns the request log' do
          VCR.use_cassette('SocialData__Client') do
            params = { query: "from:#{user.handle} within_time:24h" }
            response = client.search_tweets(params)

            # Check that tweets are returned
            expect(response['tweets'].count).to eq(39)
            response['tweets'].each do |tweet|
              tweet_created_at = Time.parse(tweet['tweet_created_at'])
              expect(tweet_created_at).to be_within(24.hours).of(vcr_response_time)

              null_tweet_keys.each do |key|
                expect(tweet[key]).to be_nil
              end

              expect(tweet).to include('user')
              expect(tweet['user'].keys).to match_array(user_keys)
              non_null_user_keys.each do |key|
                expect(tweet['user'][key]).to_not be_nil
              end
            end

            # Check that the request_log is returned
            expect(response).to include('request_log')
            expect(response['request_log']).to be_a(RequestLog)

            # Validate the contents of the request_log
            request_log = response['request_log']
            expect(request_log.endpoint).to eq('search')
            expect(request_log.params['query']).to eq("from:#{user.handle} within_time:24h")
          end
        end
      end
    end
  end

end

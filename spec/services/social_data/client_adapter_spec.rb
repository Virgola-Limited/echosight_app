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


    let(:first_tweet) {
      {
        "id"=>"1740498992587567374",
        "text"=>"test",
        "created_at"=>"2023-12-28T22:24:31.000000Z",
        "public_metrics" => {"like_count"=>0, "quote_count"=>0, "reply_count"=>0, "retweet_count"=>0}
      }
    }
  end

  describe '#fetch_user_with_metrics' do
    it 'returns adapted social data in the expected format' do
      adapted_data = client_adapter.fetch_user_with_metrics
      expect(adapted_data).to eq(adapted_user_data)
    end

    let(:adapted_user_data) {
      {
        "data" => {
          "id" => "1691930809756991488",
          "name" => "Topher",
          "username" => "TopherToy",
          "public_metrics" => {
            "followers_count" => 3,
            "following_count" => 16,
            "listed_count" => 0,
            "tweet_count" => 15
          }
        }
      }
    }
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::Client, :vcr do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity:) }
  let(:client) { described_class.new }

  # not used right now
  xdescribe '#fetch_user_tweets' do
    it 'fetches new tweets from the API' do
      expect(client.fetch_user_tweets).to eq(fetch_user_tweets_response_body)
    end
  end

  # not used right now
  xdescribe '#fetch_user_with_metrics' do
    it 'fetches user data with metrics from the API' do
      expect(client.fetch_user_with_metrics).to eq(fetch_user_with_metrics_response_body)
    end
  end

  # not used right now
  xdescribe '#fetch_tweets_by_ids' do
    it 'fetches tweets by their IDs' do
      tweet_ids = %w[1234567890 0987654321]
      tweets_data = client.fetch_tweets_by_ids(tweet_ids)
      expect(tweets_data).to eq(fetch_tweets_by_ids_response_body)
    end
  end

  let(:fetch_user_tweets_response_body) do
    { 'data' => [
      { 'id' => '1234567890', 'text' => 'This is an example tweet #1', 'created_at' => '2024-02-28T08:00:00.000Z',
        'public_metrics' => { 'retweet_count' => 10, 'reply_count' => 5, 'like_count' => 100, 'quote_count' => 1 } }, { 'id' => '0987654321', 'text' => 'This is another example tweet #2', 'created_at' => '2024-02-28T09:00:00.000Z', 'public_metrics' => { 'retweet_count' => 20, 'reply_count' => 10, 'like_count' => 150, 'quote_count' => 2 } }
    ] }
  end

  let(:fetch_tweets_by_ids_response_body) do
    { 'data' => [
      { 'id' => '1234567890', 'text' => 'Sample tweet text for ID 1234567890',
        'public_metrics' => { 'retweet_count' => 5, 'reply_count' => 2, 'like_count' => 10, 'quote_count' => 1 }, 'non_public_metrics' => { 'impression_count' => 100, 'user_profile_clicks' => 10 } }, { 'id' => '0987654321', 'text' => 'Sample tweet text for ID 0987654321', 'public_metrics' => { 'retweet_count' => 3, 'reply_count' => 1, 'like_count' => 7, 'quote_count' => 0 }, 'non_public_metrics' => { 'impression_count' => 80, 'user_profile_clicks' => 8 } }
    ] }
  end

  let(:fetch_user_with_metrics_response_body) do
    {
      'data' => {
        'id' => '1691930809756991488',
        'name' => 'Twitter Dev',
        'public_metrics' => {
          'followers_count' => 512,
          'following_count' => 165,
          'listed_count' => 14,
          'tweet_count' => 3210
        },
        'username' => 'TwitterDev'
      }
    }
  end
end

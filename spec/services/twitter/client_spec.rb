# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::Client do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity:) }
  let(:client) { described_class.new(user) }

  let(:response_body) do
    { 'data' => [
      { 'id' => '1234567890', 'text' => 'This is an example tweet #1', 'created_at' => '2024-02-28T08:00:00.000Z',
        'public_metrics' => { 'retweet_count' => 10, 'reply_count' => 5, 'like_count' => 100, 'quote_count' => 1 } }, { 'id' => '0987654321', 'text' => 'This is another example tweet #2', 'created_at' => '2024-02-28T09:00:00.000Z', 'public_metrics' => { 'retweet_count' => 20, 'reply_count' => 10, 'like_count' => 150, 'quote_count' => 2 } }
    ] }
  end

  describe '#fetch_user_tweets' do
    it 'fetches new tweets from the API', :vcr do
      expect(response_body).to eq(client.fetch_user_tweets)
    end
  end
end

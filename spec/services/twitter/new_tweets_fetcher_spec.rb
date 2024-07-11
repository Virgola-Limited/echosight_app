# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcher do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:api_batch) { create(:api_batch) }
  let(:vcr_response_time) { Time.parse('Tue, 05 Mar 2024 18:54:26 GMT') }
  let(:subject) { described_class.new(identity:, within_time: '14d', api_batch_id: api_batch.id) }
  let(:expected_tweets) { 443 }
  let(:oldest_expected_date) { vcr_response_time - 7.days }

  before do
    allow(IdentityUpdater).to receive(:new).with(any_args).and_return(double(call: nil))
  end

  it 'calls Twitter::TweetAndMetricUpserter with the correct arguments' do
    VCR.use_cassette('Twitter__TweetsFetcher_call') do
      expect(Twitter::TweetAndMetricUpserter).to receive(:call).with(tweet_data: anything, identity: identity, api_batch_id: api_batch.id, allow_update: false).exactly(expected_tweets).times
      subject.call
    end
  end

  it 'calls Twitter::TweetAndMetricUpserter with the correct arguments at least once' do
    VCR.use_cassette('Twitter__TweetsFetcher_call') do
      expect(Twitter::TweetAndMetricUpserter).to receive(:call).at_least(:once) do |args|
        expect(args[:tweet_data]).to include(
          "id",
          "text",
          "created_at",
          "public_metrics" => include("retweet_count", "reply_count", "like_count", "quote_count"),
          "user" => include("data" => include("id", "name", "username"))
        )
        expect(args[:identity]).to eq(identity)
        expect(args[:api_batch_id]).to eq(api_batch.id)
      end

      subject.call
    end
  end

  let(:expected_user_data) do
    {
      'id' => '1192091185',
      'username' => 'loftwah',
      'name' => 'Loftwah',
      'public_metrics' => {
        "followers_count"=>7065,
        "following_count"=>5043,
        "listed_count"=>45,
        "tweet_count"=>57831
      },
      'description' => "Revolutionize Your Social Media Strategy with Echosight | https://t.co/wMI0Lub79k | https://t.co/HLB3aL1jca | https://t.co/IbbT2ncYyt | https://t.co/i9vT0NmOyw",
      'image_url' => 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg',
      'can_dm' => false,
      'banner_url' => 'https://pbs.twimg.com/profile_banners/1192091185/1711023494'
    }
  end


  it 'sends todays user data to IdentityUpdater' do
    VCR.use_cassette('Twitter__TweetsFetcher_call') do
      expect(IdentityUpdater).to receive(:new).with(expected_user_data)
      subject.call
    end
  end

  context 'when impression_count is nil' do
    it 'defaults impression_count to 0' do
      VCR.use_cassette('Twitter__TweetsFetcher_call') do
        subject.call
      end
      tweet_metric = TweetMetric.first

      expect(tweet_metric.impression_count).to eq(0)
    end
  end
end

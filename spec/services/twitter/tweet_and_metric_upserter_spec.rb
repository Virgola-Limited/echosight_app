require 'rails_helper'

RSpec.describe Twitter::TweetAndMetricUpserter do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:api_batch) { create(:api_batch) }
  let(:subject) { described_class.new(user: user, tweet_data: tweet_data, api_batch_id: api_batch.id) }
  let(:tweet_data) {
  {
    "id" => "1765189290131399049",
    "text" => "@drewskadoosh @ziademarcus Are you married to a shinigami?",
    "created_at" => "2024-03-06T01:34:57.000000Z",
    "public_metrics" => {
      "retweet_count" => 1,
      "reply_count" => 2,
      "like_count" => 3,
      "quote_count" => 4,
      "impression_count" => 5,
      "bookmark_count" => nil
    },
    "is_pinned" => "false",
    "user" => {
      "data" => {
        "id" => "1192091185",
        "name" => "Loftwah",
        "username" => "loftwah",
        "public_metrics" => {
          "followers_count" => 6676,
          "following_count" => 4554,
          "listed_count" => 42,
          "tweet_count" => 52729
        },
        "description" => "Revolutionize Your Social Media Strategy with Echosight | https://t.co/wMI0LubEYS | https://t.co/HLB3aL1R1I | https://t.co/IbbT2ndwo1 | https://t.co/i9vT0Nnmo4",
        "image_url" => "https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg",
        "banner_url" => "https://pbs.twimg.com/profile_banners/1192091185/1707817030"
      }
    }
  }
}

  before do
    allow(IdentityUpdater).to receive(:new).with(any_args).and_return(double(call: nil))
  end

  let(:subject) { described_class.new(user: user, tweet_data: tweet_data, api_batch_id: api_batch.id) }

  context 'when the tweet does not exist' do
    it 'creates a new tweet and tweet metric' do
      expect {
        subject.call
      }.to change(Tweet, :count).by(1).and change(TweetMetric, :count).by(1)

      tweet = Tweet.last
      expect(tweet.text).to eq(tweet_data["text"])
      expect(tweet.identity_id).to eq(user.identity.id)
      # expect(tweet.twitter_created_at.to_s).to eq(DateTime.parse(tweet_data["created_at"]).to_s)

      tweet_metric = TweetMetric.last
      expect(tweet_metric.retweet_count).to eq(1)
      expect(tweet_metric.reply_count).to eq(2)
      expect(tweet_metric.like_count).to eq(3)
      expect(tweet_metric.quote_count).to eq(4)
      expect(tweet_metric.impression_count).to eq(5)
      expect(tweet_metric.bookmark_count).to eq(0)
    end
  end

  context 'when the tweet exists' do
    describe 'when there is a batch ID mismatch' do
      before do
        create(:tweet, id: tweet_data["id"])
      end

      it 'raises an error' do
        expect {
          subject.call
        }.to raise_error(RuntimeError, /Mismatched batch ID/)
      end
    end

    context 'when the tweet metrics update count is less than 2' do
      let!(:existing_tweet) { create(:tweet, id: tweet_data["id"], api_batch_id: api_batch.id) }
      let!(:existing_metric) { create(:tweet_metric, tweet: existing_tweet, updated_count: 1) }

      it 'updates the tweet and updates the last tweet metric' do
        expect {
          subject.call
        }.not_to change(Tweet, :count)
        expect(existing_tweet.tweet_metrics.count).to eq(1)
        expect {
          existing_metric.reload
        }.to change(existing_metric, :updated_count).from(1).to(2)
      end
    end


    context 'when the tweet metrics update count is 2 or more' do
      let!(:existing_tweet) { create(:tweet, id: tweet_data["id"], api_batch_id: api_batch.id) }
      let!(:existing_metric) { create(:tweet_metric, tweet: existing_tweet, updated_count: 2) }

      it 'updates the tweet and creates a new tweet metric' do
        expect(existing_tweet.tweet_metrics.count).to eq(1)
        expect {
          subject.call
        }.not_to change(Tweet, :count)
        expect(existing_tweet.tweet_metrics.count).to eq(2)
      end
    end
  end
end
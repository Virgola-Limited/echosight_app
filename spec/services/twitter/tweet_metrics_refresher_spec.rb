require 'rails_helper'

RSpec.describe Twitter::TweetMetricsRefresher, :vcr do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:batch_size) { 2 }
  let(:subject) { described_class.new(user: user, batch_size: batch_size) }
  let(:random_last_7_days) { rand(7.days.ago..Time.current) }

  context 'when there are outdated tweets' do
    let!(:updatable_tweets) do
      tweets = []
      valid_tweet_ids = %w[1758983678515085403]
      valid_tweet_ids.each do |id|
        tweets << create(:tweet, identity: identity, twitter_id: id, updated_at: 25.hours.ago, twitter_created_at: random_last_7_days)
      end
      tweets
    end

    let!(:outdated_tweet) do
      create(:tweet, identity: identity, twitter_created_at: 8.days.ago, updated_at: 25.hours.ago)
    end

    it 'updates metrics for outdated tweets' do
      outdated_tweet_updated_at = outdated_tweet.reload.updated_at
      expect(TweetMetric.where(tweet: updatable_tweets).count).to eq(0)
      expect(TweetMetric.where(tweet: outdated_tweet).count).to eq(0)
      expect { subject.call }.to change { updatable_tweets.map(&:reload).map(&:updated_at) }
      expect(TweetMetric.where(tweet: updatable_tweets).count).to eq(updatable_tweets.count)
      expect(TweetMetric.where(tweet: outdated_tweet).count).to eq(0)
      expect(outdated_tweet.reload.updated_at).to eq(outdated_tweet_updated_at)
    end
  end

  context 'when there are no outdated tweets' do
    it 'does not perform any updates' do
      expect { subject.call }.not_to change { TweetMetric.count }
    end
  end

end

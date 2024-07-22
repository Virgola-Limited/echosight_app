# spec/services/twitter/leaderboard_snapshot_service_spec.rb
require 'rails_helper'

RSpec.describe Twitter::LeaderboardSnapshotService do
  describe '.call' do
    let!(:identity1) { create(:identity) }
    let!(:identity2) { create(:identity) }
    let!(:tweet1) { create(:tweet, identity: identity1) }
    let!(:tweet2) { create(:tweet, identity: identity2) }
    let!(:tweet_metric1) { create(:tweet_metric, tweet: tweet1, impression_count: 100) }
    let!(:tweet_metric2) { create(:tweet_metric, tweet: tweet2, impression_count: 200) }

    before do
      allow(Twitter::LeaderboardQuery).to receive(:new).and_call_original
    end

    it 'creates a snapshot if one does not already exist for today' do
      expect {
        described_class.call
      }.to change(LeaderboardSnapshot, :count).by(1)
    end

    it 'creates leaderboard entries for the snapshot' do
      expect {
        described_class.call
      }.to change(LeaderboardEntry, :count).by(2) # Adjust this number based on the actual expected count
    end

    it 'creates leaderboard entries with correct rank' do
      described_class.call

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      expect(entries.first.rank).to eq(1)
      expect(entries.first.identity).to eq(identity2)

      expect(entries.second.rank).to eq(2)
      expect(entries.second.identity).to eq(identity1)
    end

    it 'creates leaderboard entries with correct attributes' do
      described_class.call

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      expect(entries.first.impressions).to eq(200)
      expect(entries.first.retweets).to eq(tweet_metric2.retweet_count)
      expect(entries.first.likes).to eq(tweet_metric2.like_count)
      expect(entries.first.quotes).to eq(tweet_metric2.quote_count)
      expect(entries.first.replies).to eq(tweet_metric2.reply_count)
      expect(entries.first.bookmarks).to eq(tweet_metric2.bookmark_count)

      expect(entries.second.impressions).to eq(100)
      expect(entries.second.retweets).to eq(tweet_metric1.retweet_count)
      expect(entries.second.likes).to eq(tweet_metric1.like_count)
      expect(entries.second.quotes).to eq(tweet_metric1.quote_count)
      expect(entries.second.replies).to eq(tweet_metric1.reply_count)
      expect(entries.second.bookmarks).to eq(tweet_metric1.bookmark_count)
    end

    it 'enqueues NotifyLeaderboardChangeJob' do
      allow(Twitter::NotifyLeaderboardChangeJob).to receive(:perform_async)
      described_class.call
      expect(Twitter::NotifyLeaderboardChangeJob).to have_received(:perform_async)
    end

    context 'when a snapshot already exists for today' do
      before do
        described_class.call
      end

      it 'does not create duplicate snapshots' do
        expect {
          described_class.call
        }.not_to change(LeaderboardSnapshot, :count)
      end

      it 'does not create duplicate leaderboard entries' do
        expect {
          described_class.call
        }.not_to change(LeaderboardEntry, :count)
      end

      it 'does not enqueue NotifyLeaderboardChangeJob again' do
        allow(Twitter::NotifyLeaderboardChangeJob).to receive(:perform_async)
        described_class.call
        expect(Twitter::NotifyLeaderboardChangeJob).not_to have_received(:perform_async)
      end
    end
  end
end

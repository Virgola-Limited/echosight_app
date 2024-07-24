require 'rails_helper'

RSpec.describe Twitter::LeaderboardSnapshotService do
  describe '.call' do
    let!(:identity1) { create(:identity) }
    let!(:identity2) { create(:identity) }
    let!(:tweet1) { create(:tweet, identity: identity1, twitter_created_at: 1.hour.ago) }
    let!(:tweet2) { create(:tweet, identity: identity2, twitter_created_at: 2.hours.ago) }
    let!(:tweet_metric1) { create(:tweet_metric, tweet: tweet1, impression_count: 100, retweet_count: 5, like_count: 10, quote_count: 1, reply_count: 2, bookmark_count: 3, created_at: 1.hour.ago) }
    let!(:tweet_metric2) { create(:tweet_metric, tweet: tweet2, impression_count: 200, retweet_count: 10, like_count: 20, quote_count: 2, reply_count: 4, bookmark_count: 6, created_at: 2.hours.ago) }

    it 'creates a snapshot if one does not already exist for today' do
      expect {
        described_class.call
      }.to change(LeaderboardSnapshot, :count).by(1)
    end

    it 'creates leaderboard entries for the snapshot' do
      expect {
        described_class.call
      }.to change(LeaderboardEntry, :count).by(2)
    end

    it 'creates leaderboard entries with correct rank' do
      described_class.call

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      expect(entries.first.rank).to eq(1)
      expect(entries.first.identity_id).to eq(identity2.id)

      expect(entries.second.rank).to eq(2)
      expect(entries.second.identity_id).to eq(identity1.id)
    end

    it 'creates leaderboard entries with correct attributes' do
      described_class.call

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      expect(entries.first.impressions).to eq(200)
      expect(entries.first.retweets).to eq(10)
      expect(entries.first.likes).to eq(20)
      expect(entries.first.quotes).to eq(2)
      expect(entries.first.replies).to eq(4)
      expect(entries.first.bookmarks).to eq(6)

      expect(entries.second.impressions).to eq(100)
      expect(entries.second.retweets).to eq(5)
      expect(entries.second.likes).to eq(10)
      expect(entries.second.quotes).to eq(1)
      expect(entries.second.replies).to eq(2)
      expect(entries.second.bookmarks).to eq(3)
    end

    it 'enqueues NotifyLeaderboardChangeJob if changes are made' do
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

      it 'updates the existing leaderboard entries instead of creating new ones' do
        leaderboard_entry = LeaderboardEntry.find_by(identity_id: identity1.id)
        leaderboard_entry.update!(impressions: 50)

        described_class.call
        leaderboard_entry.reload

        expect(leaderboard_entry.impressions).to eq(100)
      end

      it 'does not enqueue NotifyLeaderboardChangeJob again if no changes are made' do
        allow(Twitter::NotifyLeaderboardChangeJob).to receive(:perform_async)
        described_class.call
        expect(Twitter::NotifyLeaderboardChangeJob).not_to have_received(:perform_async)
      end
    end

    context 'when a snapshot exists for the previous day' do
      before do
        travel_to 1.day.ago do
          described_class.call
        end
      end

      it 'creates a new snapshot for today' do
        expect {
          described_class.call
        }.to change(LeaderboardSnapshot, :count).by(1)
      end

      it 'creates new leaderboard entries for today' do
        expect {
          described_class.call
        }.to change(LeaderboardEntry, :count).by(2)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Twitter::LeaderboardSnapshotService do
  describe '.capture_snapshots' do
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
        described_class.capture_snapshots
      }.to change(LeaderboardSnapshot, :count).by(1)
    end

    it 'creates leaderboard entries for the snapshot' do
      expect {
        described_class.capture_snapshots
      }.to change(LeaderboardEntry, :count).by(2) # Adjust this number based on the actual expected count
    end

    it 'creates leaderboard entries with correct rank' do
      described_class.capture_snapshots

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      expect(entries.first.rank).to eq(1)
      expect(entries.first.identity).to eq(identity2)

      expect(entries.second.rank).to eq(2)
      expect(entries.second.identity).to eq(identity1)
    end

    context 'when a snapshot already exists for today' do
      before do
        described_class.capture_snapshots
      end

      it 'does not create duplicate snapshots' do
        expect {
          described_class.capture_snapshots
        }.not_to change(LeaderboardSnapshot, :count)
      end
    end
  end
end

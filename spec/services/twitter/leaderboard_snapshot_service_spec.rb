# spec/services/twitter/leaderboard_snapshot_service_spec.rb

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

    it 'creates snapshots for each date range' do
      expect {
        described_class.capture_snapshots
      }.to change(LeaderboardSnapshot, :count).by(Twitter::LeaderboardQuery::PERIODS.keys.size)
    end

    it 'creates leaderboard entries for each snapshot' do
      expect {
        described_class.capture_snapshots
      }.to change(LeaderboardEntry, :count).by(Twitter::LeaderboardQuery::PERIODS.keys.size * 2)
    end

    it 'creates leaderboard entries with correct rank' do
      described_class.capture_snapshots

      snapshot = LeaderboardSnapshot.first
      entries = snapshot.leaderboard_entries.order(:rank)

      if entries.empty?
        puts "No entries found. Snapshot details: #{snapshot.inspect}"
        LeaderboardEntry.all.each { |entry| puts entry.inspect }
      end

      expect(entries.first.rank).to eq(1)
      expect(entries.first.identity).to eq(identity2)

      expect(entries.second.rank).to eq(2)
      expect(entries.second.identity).to eq(identity1)
    end
  end
end

require 'rails_helper'

RSpec.describe Twitter::Leaderboard::NewTopTenEntriesQuery do
  xdescribe '#call' do
    let!(:identity1) { create(:identity, handle: 'leader1') }
    let!(:identity2) { create(:identity, handle: 'leader2') }
    let!(:identity3) { create(:identity, handle: 'new_leader') }

    context 'when there are new entries in the top 10' do
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry1) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:yesterday_entry2) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity2, rank: 2) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 2) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity3, rank: 1) }

      it 'returns the new top 10 entries' do
        result = described_class.new.call
        expect(result).not_to be_nil
        expect(result.size).to eq(1)
        expect(result.first[:twitter_handle]).to eq('new_leader')
        expect(result.first[:rank]).to eq(1)
      end
    end

    context 'when there are no new entries in the top 10' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry1) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:yesterday_entry2) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity2, rank: 2) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 1) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 2) }

      it 'returns an empty array' do
        result = described_class.new.call
        expect(result).to eq([])
      end
    end
  end
end

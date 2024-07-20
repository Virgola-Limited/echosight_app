# spec/queries/twitter/leaderboard/leader_change_query_spec.rb
require 'rails_helper'

RSpec.describe Twitter::Leaderboard::LeaderChangeQuery do
  describe '#call' do
    let!(:identity1) { create(:identity, handle: 'leader1') }
    let!(:identity2) { create(:identity, handle: 'leader2') }

    context 'when the leaderboard stays the same' do
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:today_entry) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 1) }

      it 'returns nil' do
        result = described_class.new.call
        expect(result).to be_nil
      end
    end

    context 'when the leaderboard changes' do
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:today_entry) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 1) }

      it 'returns the previous and new leader information' do
        result = described_class.new.call
        expect(result).not_to be_nil
        expect(result[:previous_leader][:twitter_handle]).to eq('leader1')
        expect(result[:previous_leader][:uid]).to eq(identity1.id)
        expect(result[:new_leader][:twitter_handle]).to eq('leader2')
        expect(result[:new_leader][:uid]).to eq(identity2.id)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Twitter::LeaderboardNotificationService do
  let(:post_sender) { class_double("PostSender").as_stubbed_const }
  let(:leader_change_query) { instance_double("Twitter::Leaderboard::LeaderChangeQuery") }
  let(:new_top_ten_entries_query) { instance_double("Twitter::Leaderboard::NewTopTenEntriesQuery") }

  before do
    allow(post_sender).to receive(:new).and_return(post_sender_instance)
    allow(post_sender_instance).to receive(:call)
    allow(Twitter::Leaderboard::LeaderChangeQuery).to receive(:new).and_return(leader_change_query)
    allow(Twitter::Leaderboard::NewTopTenEntriesQuery).to receive(:new).and_return(new_top_ten_entries_query)
  end

  let(:post_sender_instance) { instance_double("PostSender") }

  describe '#run' do
    context 'when there is a leaderboard change' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1, impressions: 1000) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 1, impressions: 1000) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 2, impressions: 900) }

      before do
        allow(leader_change_query).to receive(:call).and_return({ new_leader: { twitter_handle: 'leader2' } })
        allow(new_top_ten_entries_query).to receive(:call).and_return(nil)
      end

      it 'sends a notification for leaderboard change' do
        described_class.new.run
        expect(post_sender).to have_received(:new).with(
          message: "Congratulations @leader2 on topping the leaderboard on Echosight!",
          post_type: 'once_a_week',
          channel_type: 'slack'
        )
        expect(post_sender_instance).to have_received(:call)
      end
    end

    context 'when there are new entries in the top 10' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:identity3) { create(:identity, handle: 'new_leader') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry1) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1, impressions: 1000) }
      let!(:yesterday_entry2) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity2, rank: 2, impressions: 900) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 2, impressions: 900) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity3, rank: 1, impressions: 1100) }

      before do
        allow(leader_change_query).to receive(:call).and_return(nil)
        allow(new_top_ten_entries_query).to receive(:call).and_return([{ twitter_handle: 'new_leader' }])
      end

      it 'sends a notification for new top 10 entries' do
        described_class.new.run
        expect(post_sender).to have_received(:new).with(
          message: "Congratulations to the new entries in the top 10 on Echosight: new_leader",
          post_type: 'once_a_week',
          channel_type: 'slack'
        )
        expect(post_sender_instance).to have_received(:call)
      end
    end

    context 'when there is no leaderboard change or new top 10 entries' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry1) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1, impressions: 1000) }
      let!(:yesterday_entry2) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity2, rank: 2, impressions: 900) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 1, impressions: 1000) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 2, impressions: 900) }

      before do
        allow(leader_change_query).to receive(:call).and_return(nil)
        allow(new_top_ten_entries_query).to receive(:call).and_return(nil)
      end

      it 'does not send a notification' do
        described_class.new.run
        expect(post_sender_instance).not_to have_received(:call)
      end
    end
  end
end

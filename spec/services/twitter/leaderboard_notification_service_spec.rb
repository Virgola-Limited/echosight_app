# spec/services/twitter/leaderboard_notification_service_spec.rb
require 'rails_helper'

RSpec.describe Twitter::LeaderboardNotificationService do
  let(:slack_notifier) { class_double("Notifications::SlackNotifier").as_stubbed_const }

  before do
    allow(slack_notifier).to receive(:call)
  end

  describe '#run' do
    context 'when there is a leaderboard change' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1, impressions: 1000) }
      let!(:today_entry1) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 1, impressions: 1000) }
      let!(:today_entry2) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 2, impressions: 900) }

      it 'sends a notification to Slack for leaderboard change' do
        described_class.new.run
        expect(slack_notifier).to have_received(:call).with(
          message: "Congratulations @leader2 on topping the leaderboard on Echosight!",
          channel: :general
        )
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

      it 'sends a notification to Slack for new top 10 entries' do
        described_class.new.run
        expect(slack_notifier).to have_received(:call).with(
          message: "Congratulations to the new entries in the top 10 on Echosight: new_leader",
          channel: :general
        )
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

      it 'does not send a notification to Slack' do
        described_class.new.run
        expect(slack_notifier).not_to have_received(:call)
      end
    end
  end
end

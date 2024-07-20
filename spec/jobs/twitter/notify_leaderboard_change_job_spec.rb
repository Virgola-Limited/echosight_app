require 'rails_helper'

RSpec.describe Twitter::NotifyLeaderboardChangeJob, type: :job do
  let(:slack_notifier) { class_double("Notifications::SlackNotifier").as_stubbed_const }

  before do
    allow(slack_notifier).to receive(:call)
  end

  describe '#perform' do
    context 'when there is a leaderboard change' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:identity2) { create(:identity, handle: 'leader2') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:today_entry) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity2, rank: 1) }

      it 'sends a notification to Slack' do
        described_class.new.perform
        expect(slack_notifier).to have_received(:call).with(
          message: "Congratulations @leader2 on topping the leaderboard on Echosight!",
          channel: :general
        )
      end
    end

    context 'when there is no leaderboard change' do
      let!(:identity1) { create(:identity, handle: 'leader1') }
      let!(:yesterday_snapshot) { create(:leaderboard_snapshot, captured_at: Date.yesterday) }
      let!(:today_snapshot) { create(:leaderboard_snapshot, captured_at: Date.current) }
      let!(:yesterday_entry) { create(:leaderboard_entry, leaderboard_snapshot: yesterday_snapshot, identity: identity1, rank: 1) }
      let!(:today_entry) { create(:leaderboard_entry, leaderboard_snapshot: today_snapshot, identity: identity1, rank: 1) }

      it 'does not send a notification to Slack' do
        described_class.new.perform
        expect(slack_notifier).not_to have_received(:call)
      end
    end
  end
end

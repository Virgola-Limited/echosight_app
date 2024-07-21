# spec/jobs/twitter/notify_leaderboard_change_job_spec.rb
require 'rails_helper'

RSpec.describe Twitter::NotifyLeaderboardChangeJob, type: :job do
  let(:notification_service) { instance_double("Twitter::LeaderboardNotificationService") }

  before do
    allow(Twitter::LeaderboardNotificationService).to receive(:new).and_return(notification_service)
    allow(notification_service).to receive(:run)
  end

  describe '#perform' do
    it 'calls the run method on LeaderboardNotificationService' do
      described_class.new.perform
      expect(notification_service).to have_received(:run)
    end
  end
end

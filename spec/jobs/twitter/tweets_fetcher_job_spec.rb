require 'rails_helper'
RSpec.describe Twitter::TweetsFetcherJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:another_identity) { create(:identity, :loftwah) }
    let!(:syncable_users) { [create(:user, :with_identity), create(:user, identity: another_identity)] }
    let!(:non_syncable_users) { create_list(:user, 2) }  # Assuming this user is not syncable

    before do
      # allow(User).to receive(:syncable).and_return(User.where(syncable: true))
    end

    it 'creates an ApiBatch with processing status' do
      expect { described_class.new.perform }.to change(ApiBatch, :count).by(1)
    end

    it 'enqueues NewTweetsFetcherJob and ExistingTweetsUpdaterJob for each syncable user' do
      syncable_users.each do |user|
        expect(Twitter::NewTweetsFetcherJob).to receive(:perform_async).with(user.id, anything)
        expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, user.id, anything)
      end
      described_class.new.perform
    end

    it 'does not enqueue jobs for non-syncable users' do
      non_syncable_users.each do |user|
        expect(Twitter::NewTweetsFetcherJob).not_to receive(:perform_async).with(user.id, anything)
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in).with(24.hours, user.id, anything)
      end
      described_class.new.perform
    end

    it 'updates the ApiBatch status to completed' do
      described_class.new.perform
      api_batch = ApiBatch.last
      expect(api_batch.status).to eq('completed')
      expect(api_batch.completed_at).not_to be_nil
    end
  end
end

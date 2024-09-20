require 'rails_helper'
RSpec.describe Twitter::TweetsFetcherJob, type: :job do
  include ActiveJob::TestHelper

  let(:user_without_identity) { create(:user) }
  let(:user_with_identity_no_subscription) { create(:user, :with_identity) }
  let(:user_with_identity_and_subscription) { create(:user, :with_identity, :with_subscription) }
  let(:another_identity) { create(:identity, :loftwah) }

  describe '#perform' do
    before(:each) do
      Sidekiq::Testing.fake!
    end

    let!(:syncable_users) { [user_with_identity_and_subscription] }
    let!(:non_syncable_users) { [user_without_identity, user_with_identity_no_subscription] }
    let(:api_batch) { create(:api_batch) }

    it 'creates an ApiBatch with processing status' do
      expect { described_class.new.perform }.to change(ApiBatch, :count).by(1)
    end

    it 'enqueues NewTweetsFetcherJob and ExistingTweetsUpdaterJob for each syncable user' do
      allow(ApiBatch).to receive(:create!).and_return(api_batch)

      syncable_users.each do |user|
        expect(Twitter::NewTweetsFetcherJob).to receive(:perform_async).with(user.identity.id, api_batch.id)
      end
      described_class.new.perform
    end

    it 'does not enqueue jobs for non-syncable users' do
      non_syncable_users.each do |user|
        expect(Twitter::NewTweetsFetcherJob).not_to receive(:perform_async).with(user&.identity&.id)
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

  describe '#perform' do
    before(:each) do
      Sidekiq::Testing.inline!
    end

    let!(:identity) { user_with_identity_and_subscription.identity }
    let!(:api_batch) { create(:api_batch) }

    before do
      allow(Twitter::NewTweetsFetcher).to receive(:new).and_return(double(call: nil))
    end

    it 'creates an ApiBatch with processing status' do
      expect { described_class.new.perform }.to change(ApiBatch, :count).by(1)
    end

    it 'enqueues and runs NewTweetsFetcherJob for each syncable identity' do
      expect(Twitter::NewTweetsFetcherJob).to receive(:perform_async).with(identity.id, instance_of(Integer)).and_call_original

      described_class.new.perform

      # Check that NewTweetsFetcherJob has been enqueued and executed
      expect(Sidekiq::Queues['tweet_syncing']).to_not be_empty
    end

    it 'updates the ApiBatch status to completed' do
      described_class.new.perform
      api_batch = ApiBatch.last
      expect(api_batch.status).to eq('completed')
      expect(api_batch.completed_at).not_to be_nil
    end
  end
end

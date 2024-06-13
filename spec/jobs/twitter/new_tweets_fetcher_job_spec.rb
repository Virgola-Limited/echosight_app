require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcherJob do
  subject { described_class.new }
  let(:api_batch) { create(:api_batch) }
  let(:identity) { create(:identity) }

  describe '#perform' do
    context 'when the identity_id cant be found' do
      it 'raises an error' do
        expect { subject.perform(333, api_batch.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the batch cant be found' do
      it 'raises an error' do
        expect { subject.perform(identity.id, 333) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the user can be found and the batch exists' do
      before do
        allow(Twitter::NewTweetsFetcher).to receive(:new).with(identity: identity, api_batch_id: api_batch.id).and_call_original
        allow_any_instance_of(Twitter::NewTweetsFetcher).to receive(:call)
      end

      it 'calls Twitter::NewTweetsFetcher and creates a UserTwitterDataUpdate record' do
        expect { subject.perform(identity.id, api_batch.id) }.to change { UserTwitterDataUpdate.count }.by(1)
        user_twitter_data_update = UserTwitterDataUpdate.first
        expect(user_twitter_data_update.sync_class).to eq("Twitter::NewTweetsFetcher")
      end

      it 'does not enqueue ExistingTweetsUpdaterJob if no tweets exist for the user' do
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)
        subject.perform(identity.id, api_batch.id)
      end

      context 'when there are tweets for the user in the batch' do
        before do
          allow(ApiBatch).to receive(:find).with(api_batch.id).and_return(api_batch)
          allow(api_batch.tweets).to receive(:exists?).with(identity_id: identity.id).and_return(true)
        end

        it 'enqueues ExistingTweetsUpdaterJob if there are tweets for the user' do
          expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, identity.id, api_batch.id)
          subject.perform(identity.id, api_batch.id)
        end
      end
    end
  end
end

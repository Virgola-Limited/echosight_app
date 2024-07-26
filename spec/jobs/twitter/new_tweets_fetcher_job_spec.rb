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
        allow(identity).to receive(:syncable?).and_return(true)
        expect { subject.perform(identity.id, api_batch.id) }.to change { UserTwitterDataUpdate.count }.by(1)
        user_twitter_data_update = UserTwitterDataUpdate.first
        expect(user_twitter_data_update.sync_class).to eq("Twitter::NewTweetsFetcherJob")
      end

      it 'does not create a UserTwitterDataUpdate record if identity is not syncable' do
        allow(identity).to receive(:syncable?).and_return(false)
        expect { subject.perform(identity.id, api_batch.id) }.not_to change { UserTwitterDataUpdate.count }
      end

      it 'does not enqueue ExistingTweetsUpdaterJob if no tweets exist for the user' do
        allow(identity).to receive(:syncable?).and_return(true)
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)
        subject.perform(identity.id, api_batch.id)
      end

      context 'when there are tweets for the user in the batch' do
        before do
          allow(identity).to receive(:syncable?).and_return(true)
          allow(ApiBatch).to receive(:find).with(api_batch.id).and_return(api_batch)
          allow(api_batch.tweets).to receive(:exists?).with(identity_id: identity.id).and_return(true)
        end

        it 'enqueues ExistingTweetsUpdaterJob if there are tweets for the user' do
          expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, identity.id, api_batch.id)
          subject.perform(identity.id, api_batch.id)
        end
      end
    end

    context 'when an error occurs during Twitter::NewTweetsFetcher#call' do
      let(:error_message) { "Test error message" }
      let(:backtrace) { ["line1", "line2"] }
      let(:error) { StandardError.new(error_message) }

      before do
        allow(identity).to receive(:syncable?).and_return(true)
        allow(error).to receive(:backtrace).and_return(backtrace)
        allow_any_instance_of(Twitter::NewTweetsFetcher).to receive(:call).and_raise(error)
      end

      it 'calls handle_error and updates UserTwitterDataUpdate with error message' do
        expect_any_instance_of(described_class).to receive(:handle_error).and_call_original
        expect { subject.perform(identity.id, api_batch.id) }.to raise_error(StandardError)

        user_twitter_data_update = UserTwitterDataUpdate.last
        expected_error_message = "NewTweetsFetcherJob: Failed to complete update for identity #{identity.id}: #{error_message} ApiBatch: #{api_batch.id}\nBacktrace:\nline1\nline2"
        expect(user_twitter_data_update.error_message).to eq(expected_error_message)
      end
    end
  end
end

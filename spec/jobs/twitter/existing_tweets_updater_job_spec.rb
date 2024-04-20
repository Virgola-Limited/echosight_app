require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdaterJob do
  include ActiveJob::TestHelper

  let!(:user) { create(:user, :with_identity) }
  let!(:api_batch) { create(:api_batch) }
  let(:data_update_log) { instance_double(UserTwitterDataUpdate) }

  before do
    allow(UserTwitterDataUpdate).to receive(:create!).and_return(data_update_log)
    allow(data_update_log).to receive(:update!)
  end

  describe '#perform' do
    context 'when the user cannot be found' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { described_class.new.perform(999, api_batch.id) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the ApiBatch cannot be found' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { described_class.new.perform(user.id, 999) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when update_user raises an error' do
      it 'logs the error and re-raises it' do
        allow_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:call).and_raise(StandardError.new("some error"))

        expect(data_update_log).to receive(:update!).with(hash_including(:error_message))
        expect { described_class.new.perform(user.id, api_batch.id) }.to raise_error(StandardError, /some error/)
      end
    end

    context 'when all operations are successful' do
      before do
        allow_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:call)
        allow(api_batch).to receive(:created_at).and_return(10.days.ago)
      end

      it 'updates data_update_log and schedules the next update' do
        expect(data_update_log).to receive(:update!).with(hash_including(:completed_at))
        expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, user.id, api_batch.id)
        described_class.new.perform(user.id, api_batch.id)
      end

      context 'when the ApiBatch is older than 15 days' do
        before do
          allow(api_batch).to receive(:created_at).and_return(16.days.ago)
          allow(ApiBatch).to receive(:find).with(api_batch.id).and_return(api_batch)
        end

        it 'does not schedule the next update' do
          expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)
          described_class.new.perform(user.id, api_batch.id)
        end
      end
    end
  end
end

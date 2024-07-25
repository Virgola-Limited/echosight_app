require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdaterJob do
  include ActiveJob::TestHelper

  let!(:identity) { create(:identity, :syncable_without_user) }
  let(:api_batch) { create(:api_batch) }

  describe '#perform' do
    before do
      allow(ApiBatch).to receive(:find).and_return(api_batch)
      allow(Identity).to receive_message_chain(:twitter, :where, :first).and_return(identity)
    end

    context 'when the user is syncable and the api_batch is fresh' do
      before do
        allow(identity).to receive(:syncable?).and_return(true)
        allow(api_batch).to receive(:created_at).and_return(2.days.ago + 10.minute)
      end

      it 'calls update_user and schedules next job' do
        expect_any_instance_of(Twitter::ExistingTweetsUpdaterJob).to receive(:update_user)
        expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, identity.id, api_batch.id)

        perform_enqueued_jobs do
          described_class.new.perform(identity.id, api_batch.id)
        end
      end
    end

    context 'when the user is not syncable' do
      before do
        allow(identity).to receive(:syncable?).and_return(false)
      end

      it 'does not call update_user or schedule next job' do
        expect_any_instance_of(Twitter::ExistingTweetsUpdaterJob).not_to receive(:update_user)
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)

        perform_enqueued_jobs do
          described_class.new.perform(identity.id, api_batch.id)
        end
      end
    end

    context 'when the api_batch is not fresh' do
      before do
        allow(identity).to receive(:syncable?).and_return(true)
        allow(api_batch).to receive(:created_at).and_return(4.days.ago)
      end

      it 'does not reschedule the job' do
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)

        perform_enqueued_jobs do
          described_class.new.perform(identity.id, api_batch.id)
        end
      end
    end
  end
end

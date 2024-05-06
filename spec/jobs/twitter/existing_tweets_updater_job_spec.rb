require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdaterJob do
  include ActiveJob::TestHelper

  let(:user) { create(:user, :with_identity) }
  let(:api_batch) { create(:api_batch) }

  describe '#perform' do
    before do
      allow(User).to receive(:find).and_return(user)
      allow(ApiBatch).to receive(:find).and_return(api_batch)
    end

    context 'when the user is syncable and the api_batch is fresh' do
      before do
        allow(user).to receive(:syncable?).and_return(true)
        allow(api_batch).to receive(:created_at).and_return(2.days.ago)
      end

      it 'calls update_user and schedules next job' do
        expect_any_instance_of(Twitter::ExistingTweetsUpdaterJob).to receive(:update_user)
        expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_in).with(24.hours, user.id, api_batch.id)

        perform_enqueued_jobs do
          Twitter::ExistingTweetsUpdaterJob.new.perform(user.id, api_batch.id)
        end
      end
    end

    context 'when the user is not syncable' do
      before do
        allow(user).to receive(:syncable?).and_return(false)
      end

      it 'does not call update_user or schedule next job' do
        expect_any_instance_of(Twitter::ExistingTweetsUpdaterJob).not_to receive(:update_user)
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)

        perform_enqueued_jobs do
          Twitter::ExistingTweetsUpdaterJob.new.perform(user.id, api_batch.id)
        end
      end
    end

    context 'when the api_batch is not fresh' do
      before do
        allow(user).to receive(:syncable?).and_return(true)
        allow(api_batch).to receive(:created_at).and_return(4.days.ago)
      end

      it 'does not reschedule the job' do
        expect(Twitter::ExistingTweetsUpdaterJob).not_to receive(:perform_in)

        perform_enqueued_jobs do
          Twitter::ExistingTweetsUpdaterJob.new.perform(user.id, api_batch.id)
        end
      end
    end

    xcontext 'when an exception occurs' do
      before do
        allow(user).to receive(:syncable?).and_return(true)
        allow(api_batch).to receive(:created_at).and_return(2.days.ago)
        allow_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:call).and_raise(StandardError.new("Error"))
      end

      it 'logs the error and re-raises the exception' do
        perform_enqueued_jobs do
          Twitter::ExistingTweetsUpdaterJob.new.perform(user.id, api_batch.id)
        end

        # Check that an error message was logged
        expect(UserTwitterDataUpdate.last.error_message).to include("Failed to complete update for user")
      end
    end
  end
end

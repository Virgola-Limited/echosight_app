require 'rails_helper'

RSpec.describe RemoveOldEmptyApiBatchJob do
  subject(:job) { described_class.new }

  describe '#perform' do
    let(:old_completed_at) { 25.hours.ago }

    context 'when the ApiBatch is old, completed, and empty' do
      let!(:api_batch) { create(:api_batch, status: 'completed', completed_at: old_completed_at) }

      it 'deletes the old empty api batch' do
        expect { job.perform }.to change(ApiBatch, :count).by(-1)
        expect(ApiBatch.exists?(api_batch.id)).to be false
      end
    end

    context 'when the ApiBatch is old, completed, but not empty' do
      let!(:api_batch) { create(:api_batch, status: 'completed', completed_at: old_completed_at) }
      let!(:tweet) { create(:tweet, api_batch: api_batch) }

      it 'does not delete an non-empty api batch' do
        expect { job.perform }.not_to change(ApiBatch, :count)
        expect(ApiBatch.exists?(api_batch.id)).to be true
      end
    end

    context 'when the ApiBatch is recent, completed, and empty' do
      let!(:recent_api_batch) { create(:api_batch, status: 'completed', completed_at: 2.hours.ago) }

      it 'does not delete a recent api batch' do
        expect { job.perform }.not_to change(ApiBatch, :count)
        expect(ApiBatch.exists?(recent_api_batch.id)).to be true
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcherJob do
  subject { described_class.new }
  let(:api_batch) { create(:api_batch) }
  let(:user) { create(:user, :with_identity) }

  describe '#perform' do
    context 'when the user cant be found' do
      it 'raises an error' do
        expect { subject.perform(333, api_batch.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the batch cant be found' do
      it 'raises an error' do
        expect { subject.perform(user.id, 333) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the user can be found' do
      let!(:user_2) { create(:user) }

      it 'calls Twitter::NewTweetsFetcher for each syncable user' do
        expect(Twitter::NewTweetsFetcher).to receive(:new).with(user: user, api_batch_id: api_batch.id).and_call_original
        expect_any_instance_of(Twitter::NewTweetsFetcher).to receive(:call)

        expect { subject.perform(user.id, api_batch.id) }.to change { UserTwitterDataUpdate.count }.by(1)
        user_twitter_data_update = UserTwitterDataUpdate.first
        expect(user_twitter_data_update.sync_class).to eq("Twitter::NewTweetsFetcher")
        expect(UserTwitterDataUpdate.count).to eq(1)
      end
    end
  end
end

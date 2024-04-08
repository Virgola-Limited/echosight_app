require 'rails_helper'

RSpec.describe Twitter::NewTweetsFetcherJob do
  subject { described_class.new }

  describe '#perform' do
    let(:user) { create(:user, :with_identity) }

    before do
      allow(User).to receive(:syncable).and_return([user])
    end

    it 'calls Twitter::NewTweetsFetcher for each syncable user' do
      expect(Twitter::NewTweetsFetcher).to receive(:new).with(any_args).and_call_original
      expect_any_instance_of(Twitter::NewTweetsFetcher).to receive(:call)

      expect { subject.perform }.to change { UserTwitterDataUpdate.count }.by(1)
      user_twitter_data_update = UserTwitterDataUpdate.first
      expect(user_twitter_data_update.sync_class).to eq("Twitter::NewTweetsFetcher")
    end
  end
end

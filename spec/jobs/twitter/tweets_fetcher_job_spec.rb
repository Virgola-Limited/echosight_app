require 'rails_helper'

RSpec.describe Twitter::TweetsFetcherJob do
  subject { described_class.new }

  describe '#perform' do
    let!(:user) { create(:user, :with_identity) }
    let!(:user_2) { create(:user) }

    it 'calls Twitter::NewTweetsFetcherJob and ExistingTweetsUpdaterJob for each syncable user' do
      expect(Twitter::NewTweetsFetcherJob).to receive(:perform_async).with(user.id).and_call_original
      expect(Twitter::ExistingTweetsUpdaterJob).to receive(:perform_async).with(user.id).and_call_original

      subject.perform
    end
  end
end

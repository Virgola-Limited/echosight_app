require 'rails_helper'

RSpec.describe Twitter::TweetsFetcherJob do
  subject { described_class.new }

  describe '#perform' do
    let!(:user) { create(:user, :with_identity) }  # Assuming this user is syncable
    let!(:user_2) { create(:user) }  # Assuming this user is not syncable

    it 'enqueues a UserTweetsHandlerJob for each syncable user' do
      # Assuming User.syncable is scoped to include users like `user` and exclude `user_2`
      expect(Twitter::UserTweetsHandlerJob).to receive(:perform_async).with(user.id)
      expect(Twitter::UserTweetsHandlerJob).not_to receive(:perform_async).with(user_2.id)

      subject.perform
    end
  end
end

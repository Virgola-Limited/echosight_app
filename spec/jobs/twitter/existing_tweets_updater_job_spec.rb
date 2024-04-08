require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdaterJob do
  subject { described_class.new }

  describe '#perform' do
    let!(:user) { create(:user, :with_identity) }
    let!(:user_2) { create(:user) }

    it 'calls Twitter::ExistingTweetsUpdaterJob for each syncable user' do
      expect_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:call)

      expect { subject.perform(user.id) }.to change { UserTwitterDataUpdate.count }.by(1)
      user_twitter_data_update = UserTwitterDataUpdate.first
      expect(user_twitter_data_update.sync_class).to eq("Twitter::ExistingTweetsUpdater")
      expect(UserTwitterDataUpdate.count).to eq(1)
    end
  end
end

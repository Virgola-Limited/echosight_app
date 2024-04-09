require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdaterJob, :vcr do
  subject { described_class.new }

  describe '#perform' do
    let!(:user) { create(:user, :with_identity) }
    let!(:user_2) { create(:user) }

    context 'when the user cant be found' do
      it 'raises an error' do
        expect { subject.perform(333) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the user can be found' do
      let!(:user) { create(:user, :with_identity) }

      it 'calls Twitter::ExistingTweetsUpdaterJob for each syncable user' do
        expect_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:call).and_call_original

        expect { subject.perform(user.id) }.to change { UserTwitterDataUpdate.count }.by(1)
        user_twitter_data_update = UserTwitterDataUpdate.first
        expect(user_twitter_data_update.sync_class).to eq("Twitter::ExistingTweetsUpdater")
        expect(UserTwitterDataUpdate.count).to eq(1)
      end
    end
  end
end

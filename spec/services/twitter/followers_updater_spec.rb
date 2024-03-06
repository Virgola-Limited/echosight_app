# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::FollowersUpdater, :vcr do
  let!(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity:) }
  let(:updater) { described_class.new(user:) }

  describe '#call' do
    context 'when the followers data has been updated today for that user' do
      let!(:twitter_followers_count) { create(:twitter_followers_count, identity: user.identity, date: Date.current) }

      it 'updates the existing TwitterFollowersCount' do
        expect { updater.call }.not_to change(TwitterFollowersCount, :count)
        expect(twitter_followers_count.reload.followers_count).to eq('512')
      end
    end

    context 'when the followers data has not been updated today for that user' do
      it 'creates a new TwitterFollowersCount' do
        expect { updater.call }.to change(TwitterFollowersCount, :count).by(1)
        expect(TwitterFollowersCount.last.followers_count).to eq('100')
      end
    end
  end
end

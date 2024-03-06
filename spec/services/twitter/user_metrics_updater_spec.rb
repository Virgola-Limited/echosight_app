# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::UserMetricsUpdater, :vcr do
  let!(:identity) { create(:identity, :loftwah, :with_oauth_credential) }

  let(:user_data) do
    {
      "username" => identity.handle,
      "public_metrics" => {
        "followers_count" => 6676,
        "following_count" => 4554,
        "listed_count" => 42,
        "tweet_count" => 52729
      }
    }
  end
  let(:updater) { described_class.new(user_data) }

  describe '#call' do
    context 'when the followers data has been updated today for that user' do
      let!(:twitter_user_metric) { create(:twitter_user_metric, identity: identity, date: Date.current, followers_count: 512) }

      it 'updates the existing TwitterUserMetric' do
        expect { updater.call }.not_to change(TwitterUserMetric, :count)
        expect(twitter_user_metric.reload.followers_count).to eq(user_data["public_metrics"]["followers_count"])
      end
    end

    context 'when the followers data has not been updated today for that user' do
      it 'creates a new TwitterUserMetric with the correct followers count' do
        expect { updater.call }.to change(TwitterUserMetric, :count).by(1)
        expect(TwitterUserMetric.last.followers_count).to eq(user_data["public_metrics"]["followers_count"])
      end
    end
  end
end

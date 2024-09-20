# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::UserMetricsUpdater do
  let!(:identity) { create(:identity, :loftwah, :with_oauth_credential) }
  let(:user_data) do
    {
      'id' => '1192091185',
      'username' => identity.handle,
      'public_metrics' => {
        'followers_count' => 6676,
        'following_count' => 4554,
        'listed_count' => 42,
        'tweet_count' => 52_729
      },
      'image_url' => 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg',
      'banner_url' => 'https://pbs.twimg.com/profile_banners/1192091185/1707817030'
    }
  end
  let(:fields_to_test) { %w[followers_count following_count listed_count] }
  let(:updater) { described_class.new(user_data) }

  describe '#call' do
    context 'when the followers data has been updated today for that user' do
      let!(:twitter_user_metric) do
        create(:twitter_user_metric, identity:, date: Date.current, followers_count: 512)
      end

      it 'updates the existing TwitterUserMetric' do
        expect { updater.call }.not_to change(TwitterUserMetric, :count)
        fields_to_test.each do |field|
          expect(twitter_user_metric.reload.send(field)).to eq(user_data['public_metrics'][field])
        end
      end
    end

    context 'when the followers data has not been updated today for that user' do
      let(:twitter_user_metric) { TwitterUserMetric.last }

      it 'creates a new TwitterUserMetric with the correct followers count' do
        expect { updater.call }.to change(TwitterUserMetric, :count).by(1)

        fields_to_test.each do |field|
          expect(twitter_user_metric.reload.send(field)).to eq(user_data['public_metrics'][field])
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdater do
  let(:identity) { create(:identity, :loftwah) }
  let!(:user) { create(:user, identity: identity, confirmed_at: 1.day.ago) }
  let(:client) { SocialData::ClientAdapter.new }
  let!(:tweets) do
    [
      create(:tweet, id: '1782582380721078272', identity: user.identity, api_batch: api_batch),
      create(:tweet, id: '1782582410081206271', identity: user.identity, api_batch: api_batch)
    ]
  end
  let(:api_batch) { create(:api_batch) }
  let(:service) { described_class.new(user: user, api_batch_id: api_batch.id, client: client) }
  let(:identity_updater) { instance_double(IdentityUpdater, call: []) }
  let(:user_metrics_updater) { instance_double(Twitter::UserMetricsUpdater, call: []) }
  let(:identity_parameters) { ['id', 'name', 'username', 'public_metrics', 'description', 'image_url', 'banner_url'] }

  describe '#call' do
    context 'when there are no tweets in the batch for the user' do
      let!(:user_2) { create(:user, :with_identity, confirmed_at: 1.day.ago) }

      it 'does not update any tweets' do
        service = described_class.new(user: user_2, api_batch_id: api_batch.id, client: client)
        expect(Twitter::TweetAndMetricUpserter).not_to receive(:call)
        expect(client).not_to receive(:search_tweets)
        service.call
        expect(service.updated_tweets).to be_empty
        expect(service.unupdated_tweets).to be_empty
      end
    end

    context 'when there are tweets in the batch for the user' do
      it 'updates tweets and handles them accordingly' do
        VCR.use_cassette('Twitter__ExistingTweetsUpdater') do
          expect(IdentityUpdater).to receive(:new).with(hash_including(*identity_parameters)).and_return(identity_updater)
          expect(Twitter::UserMetricsUpdater).to receive(:new).with(hash_including(*identity_parameters)).and_return(user_metrics_updater)
          expect(Twitter::TweetAndMetricUpserter).to receive(:call).exactly(22).times.and_return({ success: true })
          service.call
          expect(service.updated_tweets).not_to be_empty
          expect(service.unupdated_tweets).to be_empty
        end
      end
    end

    xcontext 'when there is a mismatch in tweet counts' do
      # add tweet to batch?
      it 'handles mismatch by notifying an exception' do
        allow(client).to receive(:search_tweets).and_return({ tweet_ids: [] }) # Mocking an empty response
        expect(ExceptionHandling).to receive(:notify_or_raise)
        service.call
      end
    end
  end
end

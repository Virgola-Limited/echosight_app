require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdater do
  let(:identity) { create(:identity, :loftwah) }
  let!(:user) { create(:user, identity: identity, confirmed_at: 1.day.ago) }
  let(:client) { SocialData::ClientAdapter.new }
  let(:tweet_ids_to_create) {
    [
      "1782605136961126562",
      "1782605405429899725",
      "1782638481090769015",
      "1782640146925634003",
      "1782648064190341511",
      "1782648485600428415",
      "1782649347097936368",
      "1782649740553048287",
      "1782652269693145287",
      "1782656658994557274",
      "1782656898891915502",
      "1782658440911061293",
      "1782658557298749524",
      "1782658845543895296",
      "1782659194925269202",
      "1782661357135098075",
      "1782661458914095313",
      "1782668267930460624",
      "1782669590713299365",
      "1782671069113164111",
      "1782671383706902763",
      "1782676620073177464"
    ]
  }
  let!(:tweets) do
    tweet_ids_to_create.each do |tweet_id|
      create(:tweet, id: tweet_id, identity: user.identity, api_batch: api_batch)
    end
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
          expect(Notifications::SlackNotifier).not_to receive(:call)
          service.call
          expect(service.updated_tweets).not_to be_empty
          expect(service.unupdated_tweets).to be_empty
        end
      end
    end

    # message: "Tweet count mismatch for user loftwah. \n\nExpected: [1782605136961126562, 1782605405429899725, 1782638481090769015, 1782640146925634003, 1782648064190341511, 1782648485600428415, 1782649347097936368, 1782649740553048287, 1782652269693145287, 1782656658994557274, 1782656898891915502, 1782658440911061293, 1782658557298749524, 1782658845543895296, 1782659194925269202, 1782661357135098075, 1782661458914095313, 1782668267930460624, 1782669590713299365, 1782671069113164111, 1782671383706902763, 1782676620073177464],  \n\nActual: [1782671383706902763, 1782671069113164111, 1782669590713299365, 1782668267930460624, 1782661458914095313, 1782661357135098075, 1782659194925269202, 1782658845543895296, 1782658557298749524, 1782658440911061293, 1782656898891915502, 1782656658994557274, 1782652269693145287, 1782649740553048287, 1782649347097936368, 1782648485600428415, 1782648064190341511, 1782640146925634003, 1782638481090769015, 1782605405429899725, 1782605136961126562],  \n\nMissing: [1782676620073177464],  \n\nExtra: []"}]
    context 'when there is a mismatch in tweet counts' do
      context 'when there is an missing tweet' do
        fit 'handles mismatch by notifying an exception' do
          VCR.use_cassette('Twitter__ExistingTweetsUpdater_missing_tweet') do
            expect { service.call }.to change { Tweet.where(status: 'potentially_deleted').count }.by(1)
            expect(Tweet.find(1782676620073177464)).to have_attributes(status: 'potentially_deleted')
          end
        end
      end
    end
  end
end

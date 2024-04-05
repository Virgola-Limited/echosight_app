require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdater do
  let(:syncable_user) { create(:user, :with_identity, confirmed_at: 1.day.ago) }
  let(:non_syncable_user) { create(:user, :with_identity, confirmed_at: nil) }
  let(:client) { double('Client') }
  let(:service) { Twitter::ExistingTweetsUpdater.new(user: syncable_user, client: client) }

  before do
    allow_any_instance_of(Twitter::ExistingTweetsUpdater).to receive(:client).and_return(client)
    allow(client).to receive(:fetch_tweets_by_ids)
  end

  describe '#call' do
    context 'when tweet exists with 1 tweet metric' do
      it 'it only attempts to update 24 hours after being created' do
        tweet = create(:tweet, identity: syncable_user.identity, twitter_created_at: Time.current)
        create(:tweet_metric, tweet: tweet, pulled_at: Time.current)

        (1..23).each do |hour|
          travel_to hour.hours.from_now do
            expect(client).not_to receive(:fetch_tweets_by_ids).with([tweet.id])
            service.call
          end
        end

        travel_to 24.hours.from_now do
          expect(client).to receive(:fetch_tweets_by_ids).with([tweet.id])
          service.call
        end
      end
    end

    context 'when tweet exists with 2 tweet metrics' do
      it 'calls fetch_tweets_by_ids with the tweet id if the last metric was pulled more than 24 hours ago' do
        tweet = create(:tweet, identity: syncable_user.identity, twitter_created_at: 48.hours.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 47.hours.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 25.hours.ago)

        expect(client).to receive(:fetch_tweets_by_ids).with([tweet.id])
        service.call
      end
    end

    context 'when tweet is 14 days old' do
      it 'calls fetch_tweets_by_ids with the tweet id if it needs updating' do
        tweet = create(:tweet, identity: syncable_user.identity, twitter_created_at: 14.days.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 13.days.ago)

        expect(client).to receive(:fetch_tweets_by_ids).with([tweet.id])
        service.call
      end
    end

    context 'when tweet is 15 days old' do
      it 'does not call fetch_tweets_by_ids with the tweet id' do
        tweet = create(:tweet, identity: syncable_user.identity, twitter_created_at: 15.days.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 14.days.ago)

        expect(client).not_to receive(:fetch_tweets_by_ids).with([tweet.id])
        service.call
      end
    end

    context 'when tweet exists for a non-syncable user' do
      let(:service) { Twitter::ExistingTweetsUpdater.new(user: non_syncable_user, client: client) }

      it 'does not call fetch_tweets_by_ids for the non-syncable user tweet' do
        tweet = create(:tweet, identity: non_syncable_user.identity, twitter_created_at: 23.hours.ago)
        create(:tweet_metric, tweet: tweet, pulled_at: 23.hours.ago)

        expect(client).not_to receive(:fetch_tweets_by_ids).with([tweet.id])
        service.call
      end
    end
  end
end

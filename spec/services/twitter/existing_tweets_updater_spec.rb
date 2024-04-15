require 'rails_helper'

RSpec.describe Twitter::ExistingTweetsUpdater do
  let!(:user) { create(:user, :with_identity, confirmed_at: 1.day.ago) }
  let(:client) { double('SocialData::ClientAdapter') }
  let(:subject) { described_class.new(user: user, client: client) }
  # let(:tweet) { create(:tweet, twitter_id: 1770016891555496274, identity: user.identity, twitter_created_at: 4.hour.ago)}
  let(:updatable_tweet) { create(:tweet, twitter_id: 1765212190418899365, identity: user.identity, twitter_created_at: Time.current)}
  # this is 1 second before the unix timestamp of the since id and and 1 second later than the max id
  let(:expected_query) { { query: "from:#{user.identity.handle} -filter:replies since_time:1709694355 until_time:1709694357" } }

  describe '#call' do
    before do
      allow(Twitter::UserMetricsUpdater).to receive(:new).and_return(double(call: nil))
      allow(IdentityUpdater).to receive(:new).and_return(double(call: nil))
    end

    context 'when dealing with 1 new tweet transitioning to an old tweet' do
      it 'it does not update the metric in the first 24 hours' do
        create(:tweet_metric, tweet: updatable_tweet, pulled_at: Time.current)
        expect(client).not_to receive(:search_tweets)
        subject.call

        1.upto(24) do |hour|
          travel_to(hour.hours.from_now) do
            begin
              expect(client).not_to receive(:search_tweets)
              subject.call
            rescue RSpec::Mocks::MockExpectationError => e
              raise "#{hour} didn't expect to call search_tweets. Original error: #{e.message}"
            end
          end
        end
      end

      let(:data_response) do
        [
          {
          'id' => '1765212190418899365',
          'text' => 'to come to',
          'created_at' => '2024-03-06T03:05:56.000000Z',
          'public_metrics' => {
            'like_count' => 0,
            'quote_count' => 0,
            'reply_count' => 0,
            'retweet_count' => 0,
            'impression_count' => 11,
            'bookmark_count' => 0
          },
          'is_pinned' => 'false',
          'user' => {
            'data' => {
              'id' => '1691930809756991488',
              'name' => 'Topher',
              'username' => 'TopherToy',
              'description' => 'Twitter/X analytics with Echosight https://t.co/uZpeIYc5Nq',
              'public_metrics' => {
                'followers_count' => 13,
                'following_count' => 21,
                'listed_count' => 0,
                'tweet_count' => 40
              },
              'image_url' => 'https://pbs.twimg.com/profile_images/1770204882819223552/vrBPzd16_normal.jpg',
              'banner_url' => 'https://pbs.twimg.com/profile_banners/1691930809756991488/1710884709'
            }
          }
        }
        ]
      end

      it 'updates the metric once every 24 hours' do
        tweet_metric = create(:tweet_metric, tweet: updatable_tweet, pulled_at: Time.current)

        travel_to(24.5.hours.from_now) do
          expect(client).to receive(:search_tweets).with(expected_query).and_return({ 'data' => data_response })
          subject.call
        end

        expect(updatable_tweet.tweet_metrics.count).to eq(2)
        26.upto(48) do |hour|
          travel_to(hour.hours.from_now) do
            begin
              expect(client).not_to receive(:search_tweets)
              subject.call
            rescue RSpec::Mocks::MockExpectationError => e
              raise "#{hour} didn't expect to call search_tweets. Original error: #{e.message}"
            end
          end
        end
      end

      it 'updates the metric again after another 24 hours' do
        create(:tweet_metric, tweet: updatable_tweet, pulled_at: Time.current)
        travel_to(24.5.hours.from_now) do
          expect(client).to receive(:search_tweets).with(expected_query).and_return({ 'data' => data_response })
          subject.call
        end

        travel_to(49.hours.from_now) do
          expect(client).to receive(:search_tweets).with(expected_query).and_return({ 'data' => data_response })
          subject.call
        end

        expect(updatable_tweet.tweet_metrics.count).to eq(3)  # Assuming data_response results in an update
      end

      it 'does not update more than 14 days' do
        skip
      end
    end

    # TODO: needs to check hourly over 24 - 48 hours
    context 'when handling a mix of new and old tweets' do
      let(:old_tweet) { create(:tweet, identity: user.identity, twitter_created_at: 2.days.ago) }
      let(:new_tweet) { create(:tweet, identity: user.identity, twitter_created_at: Time.current) }

      let(:oldest_metric) { create(:tweet_metric, tweet: old_tweet, pulled_at: 48.hours.ago) }
      let(:newest_metric) { create(:tweet_metric, tweet: old_tweet, pulled_at: 25.hours.ago) }

      let(:expected_query) do
        since_time = subject.send(:id_to_time, oldest_metric.tweet.twitter_id) - 1
        until_time = subject.send(:id_to_time, newest_metric.tweet.twitter_id) + 1
        "from:#{old_tweet.identity.handle} -filter:replies since_time:#{since_time} until_time:#{until_time}"
      end

      it 'updates old tweets and skips new tweets without metrics' do
        expect(client).to receive(:search_tweets).with(query: expected_query).and_return({ 'data' => [] })
        expect(client).not_to receive(:search_tweets).with(query: include("from:#{new_tweet.identity.handle}"))

        subject.call

        # Verifying that no new metrics were added for new_tweet
        expect(new_tweet.tweet_metrics).to be_empty
        # Assuming no new data returned, old_tweet should not have new metrics added
        expect(old_tweet.tweet_metrics.count).to eq(2)
      end
    end
  end
end

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

    context 'when the tweet has 1 tweet metric' do
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
    end

        # need a successful VCR pull to test past here

        # test scenario with just new tweets
        # test scenario with just old tweets
        # test scenario with both new and old tweets
        # test scenario when a new tweet needs updating there are tweets in the middle that dont need updating and there is a tweet at the end that needs updating if its possible
    # end
  end
end

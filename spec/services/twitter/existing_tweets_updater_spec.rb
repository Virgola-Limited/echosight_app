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
    it 'it does not update the metric in the first 23 hours' do
      VCR.use_cassette('Twitter__ExistingTweetsUpdater_call.yml') do
        create(:tweet_metric, tweet: updatable_tweet, pulled_at: Time.current)
        expect(client).not_to receive(:search_tweets)
        subject.call

        1.upto(23) do |hour|
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
    end

    it 'it updates the metric after 23 hours' do
      VCR.use_cassette('Twitter__ExistingTweetsUpdater_call.yml') do
        create(:tweet_metric, tweet: updatable_tweet, pulled_at: Time.current)
        travel_to(23.5.hours.from_now) do
          expect(client).to receive(:search_tweets).with(expected_query).and_return({ 'data' => [] })
          subject.call
        end
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
